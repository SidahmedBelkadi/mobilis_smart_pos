import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

/// Headers added to every signed request. Must match the backend middleware.
class SignedRequestHeaders {
  SignedRequestHeaders._();

  static const String deviceId = 'X-Device-Id';
  static const String timestamp = 'X-Timestamp';
  static const String nonce = 'X-Nonce';
  static const String bodySha256 = 'X-Body-SHA256';
  static const String signature = 'X-Signature';
}

/// Body hash used for multipart uploads and streams, which are not hashed.
const String unsignedPayload = 'UNSIGNED-PAYLOAD';

/// Pure functions defining exactly what is signed. Any change here must be
/// mirrored on the backend, otherwise every signature becomes invalid.
class RequestCanonicalizer {
  RequestCanonicalizer._();

  /// Freezes Map/List bodies into the JSON string Dio would send, so the hash
  /// covers the exact bytes on the wire.
  static Object? normalizeBody(Object? data) =>
      data is Map || data is List ? jsonEncode(data) : data;

  /// Lowercase hex SHA-256 of the body bytes, or [unsignedPayload].
  static String bodySha256(Object? data) {
    if (data == null) return sha256.convert(const <int>[]).toString();
    if (data is String) return sha256.convert(utf8.encode(data)).toString();
    if (data is List<int>) return sha256.convert(data).toString();
    // FormData, streams...: cannot be hashed before sending.
    if (data is FormData || data is Stream) return unsignedPayload;
    return sha256.convert(utf8.encode(data.toString())).toString();
  }

  /// Path and raw (still encoded) query, as sent on the wire, without host.
  static String pathAndQuery(Uri uri) => uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path;

  static String canonicalRequest({
    required String method,
    required Uri uri,
    required String timestamp,
    required String nonce,
    required String bodySha256,
    required String deviceId,
  }) =>
      [method.toUpperCase(), pathAndQuery(uri), timestamp, nonce, bodySha256, deviceId].join('\n');

  /// Random UUID v4, unique per request (anti-replay).
  static String generateNonce([Random? random]) {
    final rnd = random ?? Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
