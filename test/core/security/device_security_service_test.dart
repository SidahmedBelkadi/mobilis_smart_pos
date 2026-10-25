import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobilis_smart_pos/src/core/security/device_enrollment_api.dart';
import 'package:mobilis_smart_pos/src/core/security/device_key_store.dart';
import 'package:mobilis_smart_pos/src/core/security/device_security_service.dart';
import 'package:mobilis_smart_pos/src/core/security/request_canonicalizer.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// In-memory key store: the "signature" is a SHA-256 of the message, enough
/// to check what gets signed without the Android Keystore.
class FakeDeviceKeyStore implements DeviceKeyStore {
  bool keyExists = false;
  int generations = 0;
  Uint8List? lastChallenge;

  @override
  Future<bool> hasKey({String? alias}) async => keyExists;

  @override
  Future<DeviceKeyGeneration> generateKey(Uint8List challenge, {String? alias}) async {
    keyExists = true;
    generations++;
    lastChallenge = challenge;
    return const DeviceKeyGeneration(
      certChain: ['leaf', 'intermediate', 'root'],
      attested: true,
      attestationError: null,
      securityLevel: 'TEE',
    );
  }

  @override
  Future<String> sign(String message, {String? alias}) async =>
      'sig:${sha256.convert(utf8.encode(message))}';

  @override
  Future<bool> verify(String message, String signature, {String? alias}) async =>
      signature == await sign(message);

  @override
  Future<String?> publicKey({String? alias}) async => 'public-key';

  @override
  Future<void> deleteKey({String? alias}) async => keyExists = false;

  @override
  Future<Map<String, dynamic>> describeAttestation({String? alias}) async => {};

  @override
  Future<Map<String, dynamic>> deviceInfo() async =>
      {'manufacturer': 'samsung', 'model': 'SM-A155F', 'androidVersion': '14'};
}

class FakeEnrollmentApi implements DeviceEnrollmentApi {
  int challenges = 0;
  int registrations = 0;
  DeviceRegistrationRequest? lastRequest;
  bool fail = false;
  DeviceEnrollmentRefused? refuse;

  @override
  String backendId = 'fake';

  @override
  Future<DeviceChallenge> getChallenge() async {
    challenges++;
    if (fail) throw Exception('backend down');
    return DeviceChallenge(
      challengeId: 'challenge-$challenges',
      nonce: base64Encode(List<int>.filled(32, 7)),
      serverTime: DateTime(2026, 1, 1, 12, 0, 10).millisecondsSinceEpoch,
    );
  }

  @override
  Future<DeviceRegistration> register(DeviceRegistrationRequest request) async {
    if (refuse != null) throw refuse!;
    registrations++;
    lastRequest = request;
    return DeviceRegistration(deviceId: 'device-$registrations', status: 'ACTIVE');
  }
}

void main() {
  late FakeDeviceKeyStore keyStore;
  late FakeEnrollmentApi api;
  final phoneNow = DateTime(2026, 1, 1, 12, 0, 0);

  DeviceSecurityService newService() => DeviceSecurityService(
        keyStore: keyStore,
        api: api,
        storage: const FlutterSecureStorage(),
        now: () => phoneNow,
      );

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    FlutterSecureStorage.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Smart POS',
      packageName: 'com.ai_univers.smart_point_of_sale',
      version: '3.1.0',
      buildNumber: '1',
      buildSignature: '',
    );
    keyStore = FakeDeviceKeyStore();
    api = FakeEnrollmentApi();
  });

  test('enrolls with the backend nonce and sends the certificate chain', () async {
    final service = newService();

    expect(await service.ensureEnrolled(), isTrue);
    expect(service.deviceId, 'device-1');
    expect(keyStore.lastChallenge, List<int>.filled(32, 7));
    expect(api.lastRequest!.challengeId, 'challenge-1');
    expect(api.lastRequest!.certChain, ['leaf', 'intermediate', 'root']);
    expect(api.lastRequest!.model, 'samsung SM-A155F');
    expect(api.lastRequest!.appVersion, '3.1.0');
  });

  test('concurrent callers share a single enrollment', () async {
    final service = newService();
    await Future.wait([service.ensureEnrolled(), service.ensureEnrolled(), service.ensureEnrolled()]);
    expect(api.registrations, 1);
  });

  test('reuses the stored deviceId on next launch', () async {
    await newService().ensureEnrolled();
    final relaunched = newService();

    expect(await relaunched.ensureEnrolled(), isTrue);
    expect(relaunched.deviceId, 'device-1');
    expect(api.registrations, 1);
  });

  test('re-enrolls when the key disappeared (app data cleared)', () async {
    await newService().ensureEnrolled();
    keyStore.keyExists = false;

    final relaunched = newService();
    expect(await relaunched.ensureEnrolled(), isTrue);
    expect(relaunched.deviceId, 'device-2');
  });

  test('re-enrolls when switching from the mock to the real backend', () async {
    await newService().ensureEnrolled();
    api.backendId = 'https://real-backend';

    final relaunched = newService();
    await relaunched.ensureEnrolled();
    expect(relaunched.deviceId, 'device-2');
  });

  test('waits for the cooldown after a failed enrollment', () async {
    api.fail = true;
    final service = newService();

    expect(await service.ensureEnrolled(), isFalse);
    expect(await service.ensureEnrolled(), isFalse);
    expect(api.challenges, 1);
  });

  test('signs requests with the server-corrected clock', () async {
    final service = newService();
    final options = RequestOptions(
      method: 'POST',
      baseUrl: 'https://api.example.dz',
      path: '/api/refresh',
      data: {'token': 'abc'},
    );

    expect(await service.signRequest(options), isTrue);

    final headers = options.headers;
    // Server clock is 10 s ahead of the phone.
    expect(headers[SignedRequestHeaders.timestamp], '${phoneNow.millisecondsSinceEpoch + 10000}');
    expect(options.data, '{"token":"abc"}');
    expect(headers[SignedRequestHeaders.bodySha256], RequestCanonicalizer.bodySha256('{"token":"abc"}'));

    final canonical = RequestCanonicalizer.canonicalRequest(
      method: 'POST',
      uri: options.uri,
      timestamp: headers[SignedRequestHeaders.timestamp],
      nonce: headers[SignedRequestHeaders.nonce],
      bodySha256: headers[SignedRequestHeaders.bodySha256],
      deviceId: 'device-1',
    );
    expect(headers[SignedRequestHeaders.signature], await keyStore.sign(canonical));
  });

  test('a refused attestation is not retried during the same run', () async {
    api.refuse = const DeviceEnrollmentRefused('DEVICE_NOT_SUPPORTED', 'UNTRUSTED_ROOT');
    final service = newService();

    expect(await service.ensureEnrolled(), isFalse);
    expect(service.refusal?.code, 'DEVICE_NOT_SUPPORTED');
    expect(await service.ensureEnrolled(), isFalse);
    expect(api.challenges, 1);
  });

  test('automatic re-enrollment happens at most once per app start', () async {
    final service = newService();
    await service.ensureEnrolled();

    expect(await service.reEnroll(), isTrue);
    expect(service.deviceId, 'device-2');
    expect(await service.reEnroll(), isFalse);
    expect(api.registrations, 2);
  });

  test('the clock can be synced from the server Date header', () async {
    final service = newService();
    service.syncClockFromServerDate(phoneNow.add(const Duration(seconds: 30)));
    expect(service.nowMs, phoneNow.millisecondsSinceEpoch + 30000);
  });
}
