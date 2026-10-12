import 'dart:convert';

import 'package:dio/dio.dart';

import 'device_security_config.dart';
import 'device_security_logger.dart';
import 'device_security_service.dart';

/// Signs outgoing requests with the device key (see [DeviceSecurityConfig])
/// and recovers from the device errors returned by the backend.
class DeviceSignatureInterceptor extends Interceptor {
  static const String skipSignatureHeader = 'skip-signature';
  static const String _retriedKey = 'device_signature_retried';

  final Dio client;
  final DeviceSecurityService security;

  DeviceSignatureInterceptor({required this.client, required this.security});

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final skipped = options.headers.remove(skipSignatureHeader) != null;
    final path = options.uri.path;
    if (!skipped && DeviceSecurityConfig.shouldSign(path)) {
      try {
        await security.signRequest(options);
      } catch (e) {
        // Never block the user on a local failure: the backend decides.
        securityLog('❌ Échec de signature de ${options.method} $path : $e');
      }
    } else if (DeviceSecurityConfig.enabled) {
      securityLog('→ ${options.method} $path : non signée '
          '(${skipped ? 'exclue explicitement' : 'hors liste des endpoints signés'})');
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final code = _errorCode(err.response?.data);
    final alreadyRetried = options.extra[_retriedKey] == true;

    if (!DeviceSecurityConfig.enabled || code == null) return handler.next(err);

    securityLog('⬅️ ${options.method} ${options.uri.path} : HTTP ${err.response?.statusCode} code=$code');
    if (alreadyRetried) {
      securityLog('    déjà réessayée une fois : abandon');
      return handler.next(err);
    }

    try {
      switch (code) {
        case 'DEVICE_NOT_ENROLLED':
        case 'DEVICE_REVOKED':
          securityLog('    → ré-enrôlement puis nouvel essai');
          await security.reset();
          if (!await security.ensureEnrolled()) return handler.next(err);
          break;
        case 'TIMESTAMP_SKEW':
          securityLog('    → resynchronisation de l\'horloge puis nouvel essai');
          await security.syncClock();
          break;
        default:
          // DEVICE_NOT_APPROVED, SIGNATURE_INVALID, NONCE_REPLAY...: no automatic retry.
          securityLog('    → pas de nouvel essai automatique pour ce code');
          return handler.next(err);
      }
      options.extra[_retriedKey] = true;
      // Goes through the interceptors again, so it gets a fresh signature.
      final response = await client.fetch(options);
      securityLog('    ✅ nouvel essai réussi : HTTP ${response.statusCode}');
      handler.resolve(response);
    } on DioException catch (retryError) {
      securityLog('    ❌ nouvel essai échoué : HTTP ${retryError.response?.statusCode}');
      handler.next(retryError);
    } catch (e) {
      securityLog('    ❌ récupération impossible : $e');
      handler.next(err);
    }
  }

  /// Backend errors look like {"code": "DEVICE_NOT_ENROLLED", ...}.
  static String? _errorCode(Object? data) {
    try {
      final json = data is String ? jsonDecode(data) : data;
      return json is Map ? json['code'] as String? : null;
    } catch (_) {
      return null;
    }
  }
}
