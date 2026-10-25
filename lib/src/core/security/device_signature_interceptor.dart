import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../app.dart';
import '../../config/routing/app_routes.dart';
import '../../dependency_injection/injection_container.dart' as di;
import '../../features/sign_in/data/data_sources/smart_pos_local_storage.dart';
import 'device_security_config.dart';
import 'device_security_logger.dart';
import 'device_security_service.dart';

/// Signs outgoing API requests with the device key (see [DeviceSecurityConfig])
/// and reacts to the backend refusals ({"error": "app_signature_refused", "code": ...}).
///
/// Never loops: at most one automatic retry per request, and the service allows
/// at most one automatic re-enrollment per app start.
class DeviceSignatureInterceptor extends Interceptor {
  static const String skipSignatureHeader = 'skip-signature';
  static const String _retriedKey = 'device_signature_retried';
  static const String _signedKey = 'device_signature_signed';

  /// After this many SIGNATURE_INVALID in a row, the key is replaced.
  static const int maxConsecutiveInvalidSignatures = 3;

  final Dio client;
  final DeviceSecurityService security;
  int _consecutiveInvalidSignatures = 0;
  bool _blockingScreenShown = false;

  DeviceSignatureInterceptor({required this.client, required this.security});

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final skipped = options.headers.remove(skipSignatureHeader) != null;
    final path = options.uri.path;
    if (!skipped && DeviceSecurityConfig.shouldSign(options.uri)) {
      try {
        options.extra[_signedKey] = await security.signRequest(options);
      } catch (e) {
        // Never block the user on a local failure: the backend decides.
        securityLog('❌ Échec de signature de ${options.method} $path : $e');
      }
    } else if (DeviceSecurityConfig.enabled && DeviceSecurityConfig.isApiRequest(options.uri)) {
      securityLog('→ ${options.method} $path : non signée (enrôlement)');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.requestOptions.extra[_signedKey] == true) _consecutiveInvalidSignatures = 0;
    handler.next(response);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final code = _refusalCode(err.response?.data);
    if (!DeviceSecurityConfig.enabled || code == null) return handler.next(err);

    securityLog('⬅️ ${options.method} ${options.uri.path} : HTTP ${err.response?.statusCode} code=$code');
    try {
      final shouldRetry = await _recover(code, err);
      if (!shouldRetry) return handler.next(err);
      if (options.extra[_retriedKey] == true) {
        securityLog('    déjà réessayée une fois : abandon');
        return handler.next(err);
      }
      options.extra[_retriedKey] = true;
      // Goes through the interceptors again: new timestamp, nonce and signature.
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

  /// Applies the backend contract for [code]. Returns true when the request should be retried.
  Future<bool> _recover(String code, DioException err) async {
    switch (code) {
      case 'DEVICE_NOT_ENROLLED':
      case 'DEVICE_REVOKED':
        securityLog('    → ré-enrôlement puis nouvel essai');
        if (await security.reEnroll()) return true;
        _showBlockingScreenIfRefused();
        return false;
      case 'SIGNATURE_MISSING':
        // The app always signs when enabled: missing means enrollment failed or was refused.
        _showBlockingScreenIfRefused();
        return false;
      case 'TIMESTAMP_SKEW':
        securityLog('    → resynchronisation de l\'horloge puis nouvel essai');
        final serverDate = _serverDate(err.response);
        if (serverDate != null) {
          security.syncClockFromServerDate(serverDate);
        } else {
          await security.syncClock();
        }
        return true;
      case 'NONCE_REPLAY':
        securityLog('    → nouvel essai avec un nouveau nonce');
        return true;
      case 'SIGNATURE_INVALID':
        _consecutiveInvalidSignatures++;
        securityLog('    signature invalide ($_consecutiveInvalidSignatures/$maxConsecutiveInvalidSignatures d\'affilée)');
        if (_consecutiveInvalidSignatures >= maxConsecutiveInvalidSignatures) {
          _consecutiveInvalidSignatures = 0;
          securityLog('    → remplacement de la clé (ré-enrôlement)');
          await security.reEnroll();
        }
        return false;
      case 'TOKEN_DEVICE_MISMATCH':
        securityLog('    → session ouverte sur un autre appareil : déconnexion locale');
        await di.serviceLocator<SmartPosLocalStorage>().clearLoginCredentials();
        navigatorKey.currentState?.pushNamedAndRemoveUntil(Routes.signIn, (route) => false);
        return false;
      default:
        // BODY_MISMATCH and unknown codes: app bug or tampering, no retry.
        securityLog('    → pas de nouvel essai automatique pour ce code');
        return false;
    }
  }

  /// Blocking screen only when the backend actually refuses our requests AND
  /// refused this phone's attestation (in observe mode requests still pass).
  void _showBlockingScreenIfRefused() {
    final refusal = security.refusal;
    if (refusal == null || _blockingScreenShown) return;
    _blockingScreenShown = true;
    securityLog('    → écran « appareil non pris en charge » (${refusal.code} / ${refusal.reason})');
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      Routes.deviceNotSupported,
      (route) => false,
      arguments: refusal.code,
    );
  }

  static DateTime? _serverDate(Response? response) {
    final value = response?.headers.value(HttpHeaders.dateHeader);
    if (value == null) return null;
    try {
      return HttpDate.parse(value);
    } catch (_) {
      return null;
    }
  }

  /// Only the official app check refusals: {"error": "app_signature_refused", "code": ...}.
  static String? _refusalCode(Object? data) {
    try {
      final json = data is String ? jsonDecode(data) : data;
      if (json is! Map || json['error'] != 'app_signature_refused') return null;
      return json['code'] as String?;
    } catch (_) {
      return null;
    }
  }
}
