import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'device_enrollment_api.dart';
import 'device_key_store.dart';
import 'device_security_logger.dart';
import 'request_canonicalizer.dart';

/// Owns the device identity: enrollment, deviceId, clock offset and request
/// signing. Only the deviceId is stored on the Dart side; the private key
/// stays in the Android Keystore.
class DeviceSecurityService {
  static const _deviceIdKey = 'device_security.device_id';
  static const _statusKey = 'device_security.status';
  static const _attestedKey = 'device_security.attested';
  static const _backendKey = 'device_security.backend';

  /// Avoid hammering the backend when enrollment keeps failing.
  static const Duration retryCooldown = Duration(minutes: 1);

  final DeviceKeyStore keyStore;
  final DeviceEnrollmentApi api;
  final FlutterSecureStorage storage;
  final DateTime Function() _now;

  String? _deviceId;
  String? _status;
  bool _attested = false;
  int _clockOffsetMs = 0;
  bool _loaded = false;
  Future<bool>? _enrollment;
  DateTime? _lastFailure;

  DeviceSecurityService({
    required this.keyStore,
    required this.api,
    required this.storage,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  String? get deviceId => _deviceId;
  String? get status => _status;
  bool get attested => _attested;
  bool get isEnrolled => _deviceId != null;

  /// Phone clock corrected with the server time received at enrollment.
  int get nowMs => _now().millisecondsSinceEpoch + _clockOffsetMs;

  /// Idempotent: concurrent callers share the same enrollment.
  /// Returns true when the device has a usable deviceId and key.
  Future<bool> ensureEnrolled() {
    return _enrollment ??= _ensureEnrolled().whenComplete(() => _enrollment = null);
  }

  Future<bool> _ensureEnrolled() async {
    await _load();
    final hasKey = await keyStore.hasKey();

    // deviceId and key must exist together, and come from the current backend.
    if (_deviceId != null && hasKey) return true;
    securityLog('Enrôlement nécessaire (deviceId: ${_deviceId ?? 'absent'}, clé Keystore: '
        '${hasKey ? 'présente' : 'absente'}, backend: ${api.backendId})');

    if (_lastFailure != null && _now().difference(_lastFailure!) < retryCooldown) {
      final wait = retryCooldown - _now().difference(_lastFailure!);
      securityLog('⏳ Enrôlement ignoré : dernier échec trop récent, nouvel essai dans ${wait.inSeconds}s');
      return false;
    }

    final stopwatch = Stopwatch()..start();
    try {
      await _enroll();
      _lastFailure = null;
      securityLog('✅ Enrôlement terminé en ${stopwatch.elapsedMilliseconds} ms');
      return true;
    } catch (e) {
      _lastFailure = _now();
      securityLog('❌ Enrôlement échoué après ${stopwatch.elapsedMilliseconds} ms : $e');
      return false;
    }
  }

  Future<void> _enroll() async {
    await _clear();

    securityLog('1/3 Demande du challenge…');
    final challenge = await api.getChallenge();
    _clockOffsetMs = challenge.serverTime - _now().millisecondsSinceEpoch;
    securityLog('    challengeId=${challenge.challengeId}, nonce=${challenge.nonceBytes.length} octets, '
        'décalage horloge serveur=${_clockOffsetMs} ms');

    securityLog('2/3 Génération de la clé dans Android Keystore…');
    final key = await keyStore.generateKey(challenge.nonceBytes);
    securityLog('    attestée=${key.attested}, niveau=${key.securityLevel}, '
        'certificats=${key.certChain.length}'
        '${key.attestationError != null ? ', erreur attestation=${key.attestationError}' : ''}');
    if (!key.attested) {
      securityLog('    ⚠️ Pas d\'attestation : le backend ne pourra pas prouver que la clé vient de notre APK');
    }
    final device = await keyStore.deviceInfo();
    final package = await PackageInfo.fromPlatform();
    securityLog('    appareil=${device['manufacturer']} ${device['model']}, Android ${device['androidVersion']}, '
        'app ${package.version}');

    final registration = await api.register(DeviceRegistrationRequest(
      challengeId: challenge.challengeId,
      certChain: key.certChain,
      attested: key.attested,
      model: '${device['manufacturer']} ${device['model']}',
      androidVersion: '${device['androidVersion']}',
      appVersion: package.version,
    ));

    securityLog('3/3 Enregistré : deviceId=${registration.deviceId}, statut=${registration.status}');
    _deviceId = registration.deviceId;
    _status = registration.status;
    _attested = key.attested;
    await storage.write(key: _deviceIdKey, value: _deviceId);
    await storage.write(key: _statusKey, value: _status);
    await storage.write(key: _attestedKey, value: '$_attested');
    await storage.write(key: _backendKey, value: api.backendId);
  }

  /// Re-reads the server time, e.g. after a TIMESTAMP_SKEW error.
  Future<void> syncClock() async {
    final challenge = await api.getChallenge();
    _clockOffsetMs = challenge.serverTime - _now().millisecondsSinceEpoch;
    securityLog('Horloge resynchronisée : décalage=${_clockOffsetMs} ms');
  }

  /// Forgets the device (key + deviceId). Next [ensureEnrolled] re-enrolls.
  Future<void> reset() async {
    securityLog('Réinitialisation : suppression de la clé et du deviceId');
    await _load();
    await _clear();
    _lastFailure = null;
  }

  /// Adds the X-* signature headers to [options]. Returns false when the
  /// device is not enrolled (the request then goes out unsigned).
  Future<bool> signRequest(RequestOptions options) async {
    if (!await ensureEnrolled()) {
      securityLog('⚠️ ${options.method} ${options.uri.path} envoyée SANS signature (appareil non enrôlé)');
      return false;
    }

    options.data = RequestCanonicalizer.normalizeBody(options.data);
    final bodyHash = RequestCanonicalizer.bodySha256(options.data);
    final timestamp = nowMs.toString();
    final nonce = RequestCanonicalizer.generateNonce();
    final canonical = RequestCanonicalizer.canonicalRequest(
      method: options.method,
      uri: options.uri,
      timestamp: timestamp,
      nonce: nonce,
      bodySha256: bodyHash,
      deviceId: _deviceId!,
    );

    options.headers.addAll({
      SignedRequestHeaders.deviceId: _deviceId,
      SignedRequestHeaders.timestamp: timestamp,
      SignedRequestHeaders.nonce: nonce,
      SignedRequestHeaders.bodySha256: bodyHash,
      SignedRequestHeaders.signature: await keyStore.sign(canonical),
    });
    return true;
  }

  Future<void> _load() async {
    if (_loaded) return;
    final backend = await storage.read(key: _backendKey);
    if (backend == api.backendId) {
      _deviceId = await storage.read(key: _deviceIdKey);
      _status = await storage.read(key: _statusKey);
      _attested = await storage.read(key: _attestedKey) == 'true';
      securityLog('Identité chargée du stockage : deviceId=${_deviceId ?? 'aucun'}, statut=$_status, '
          'attestée=$_attested');
    } else if (backend != null) {
      securityLog('deviceId stocké pour un autre backend ($backend) : ignoré, ré-enrôlement');
    } else {
      securityLog('Aucune identité stockée (premier lancement)');
    }
    _loaded = true;
  }

  Future<void> _clear() async {
    _deviceId = null;
    _status = null;
    _attested = false;
    await keyStore.deleteKey();
    for (final key in [_deviceIdKey, _statusKey, _attestedKey, _backendKey]) {
      await storage.delete(key: key);
    }
  }
}
