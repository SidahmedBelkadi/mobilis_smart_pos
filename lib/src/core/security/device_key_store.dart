import 'dart:convert';

import 'package:flutter/services.dart';

/// Result of a key generation in the Android Keystore.
class DeviceKeyGeneration {
  /// Base64 DER certificates, leaf first. Sent as-is to the backend.
  final List<String> certChain;

  /// False when the device refused key attestation (the key still works for
  /// signing, but the backend cannot prove which app created it).
  final bool attested;
  final String? attestationError;

  /// STRONGBOX, TEE, SOFTWARE or UNKNOWN.
  final String securityLevel;

  const DeviceKeyGeneration({
    required this.certChain,
    required this.attested,
    required this.attestationError,
    required this.securityLevel,
  });

  factory DeviceKeyGeneration.fromMap(Map<dynamic, dynamic> map) => DeviceKeyGeneration(
        certChain: List<String>.from(map['certChain'] as List),
        attested: map['attested'] as bool,
        attestationError: map['attestationError'] as String?,
        securityLevel: map['securityLevel'] as String,
      );
}

/// Access to the device signing key. The private key never reaches Dart.
abstract class DeviceKeyStore {
  Future<bool> hasKey({String? alias});
  Future<DeviceKeyGeneration> generateKey(Uint8List challenge, {String? alias});

  /// ECDSA P-256 / SHA-256 signature of the UTF-8 [message], DER, base64.
  Future<String> sign(String message, {String? alias});
  Future<bool> verify(String message, String signature, {String? alias});
  Future<String?> publicKey({String? alias});
  Future<void> deleteKey({String? alias});
  Future<Map<String, dynamic>> describeAttestation({String? alias});
  Future<Map<String, dynamic>> deviceInfo();
}

class MethodChannelDeviceKeyStore implements DeviceKeyStore {
  static const _channel = MethodChannel('smartpos/device_security');

  @override
  Future<bool> hasKey({String? alias}) async =>
      await _channel.invokeMethod<bool>('hasKey', {'alias': alias}) ?? false;

  @override
  Future<DeviceKeyGeneration> generateKey(Uint8List challenge, {String? alias}) async {
    final result = await _channel.invokeMapMethod<dynamic, dynamic>(
      'generateKey',
      {'alias': alias, 'challenge': challenge},
    );
    return DeviceKeyGeneration.fromMap(result!);
  }

  @override
  Future<String> sign(String message, {String? alias}) async =>
      (await _channel.invokeMethod<String>(
        'sign',
        {'alias': alias, 'data': Uint8List.fromList(utf8.encode(message))},
      ))!;

  @override
  Future<bool> verify(String message, String signature, {String? alias}) async =>
      await _channel.invokeMethod<bool>('verify', {
        'alias': alias,
        'data': Uint8List.fromList(utf8.encode(message)),
        'signature': signature,
      }) ??
      false;

  @override
  Future<String?> publicKey({String? alias}) =>
      _channel.invokeMethod<String>('publicKey', {'alias': alias});

  @override
  Future<void> deleteKey({String? alias}) => _channel.invokeMethod('deleteKey', {'alias': alias});

  @override
  Future<Map<String, dynamic>> describeAttestation({String? alias}) async =>
      _toJsonMap(await _channel.invokeMethod('describeAttestation', {'alias': alias}));

  @override
  Future<Map<String, dynamic>> deviceInfo() async =>
      _toJsonMap(await _channel.invokeMethod('deviceInfo'));

  /// Platform maps arrive as Map<Object?, Object?>; normalise them for jsonEncode.
  static Map<String, dynamic> _toJsonMap(Object? value) =>
      jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
}
