import 'package:flutter/foundation.dart';

import '../api/end_points.dart';

/// Switches for the device key / request signing mechanism.
///
/// OFF by default until the F5 and the backend are ready. Enable at build time:
///   flutter run --dart-define=DEVICE_SECURITY_ENABLED=true
/// Once released, the app must always sign: the backend decides with its own
/// switch (ms_settings.app_signature_mode: off / observe / enforce).
class DeviceSecurityConfig {
  DeviceSecurityConfig._();

  /// Master switch: enrollment at startup + signature of every API request.
  static const bool enabled = bool.fromEnvironment('DEVICE_SECURITY_ENABLED');

  /// Local fake of /device/challenge and /device/register (no backend needed).
  /// Mock deviceIds are not UUIDs: the real backend rejects them.
  static const bool useMockBackend = bool.fromEnvironment('DEVICE_SECURITY_MOCK');

  /// Never signed: they are protected by the attestation itself.
  static const List<String> unsignedPathSuffixes = [
    '/device/challenge',
    '/device/register',
  ];

  /// Diagnostic screen (long press on the version badge). Debug builds only.
  static const bool diagnosticEnabled = kDebugMode;

  /// One-line summary printed at startup in debug builds.
  static String describe() => enabled
      ? 'ACTIVÉ | backend ${useMockBackend ? 'SIMULÉ (mock)' : 'RÉEL'} | '
          'signature : toutes les requêtes vers ${EndPoints.baseUrl} | '
          'diagnostic : ${diagnosticEnabled ? 'oui (appui long sur la version)' : 'non'}'
      : 'DÉSACTIVÉ (lancer avec --dart-define=DEVICE_SECURITY_ENABLED=true) | '
          'diagnostic : ${diagnosticEnabled ? 'oui (appui long sur la version)' : 'non'}';

  /// Every request to our API is signed (backend contract: all /app routes),
  /// except enrollment. Other hosts (OCR server, images) are never signed.
  static bool shouldSign(Uri uri) {
    if (!enabled || !isApiRequest(uri)) return false;
    return !unsignedPathSuffixes.any(uri.path.endsWith);
  }

  static bool isApiRequest(Uri uri) {
    final api = Uri.tryParse(EndPoints.baseUrl);
    if (api == null || api.host.isEmpty) return false;
    return uri.host == api.host && uri.path.startsWith(api.path);
  }
}
