import 'package:flutter/foundation.dart';

/// Switches for the device key / request signing mechanism.
///
/// Everything is OFF by default, so production behaviour is unchanged until
/// the backend is ready. Enable at build time, for example:
///   flutter run --dart-define=DEVICE_SECURITY_ENABLED=true
class DeviceSecurityConfig {
  DeviceSecurityConfig._();

  /// Master switch: enrollment at startup + signature of the requests below.
  static const bool enabled = bool.fromEnvironment('DEVICE_SECURITY_ENABLED');

  /// Use a local fake of /device/challenge and /device/register while the
  /// backend endpoints do not exist. Set to false once they are deployed.
  static const bool useMockBackend =
      bool.fromEnvironment('DEVICE_SECURITY_MOCK', defaultValue: true);

  /// Sign every request instead of only [signedPathSuffixes].
  static const bool signAllRequests = bool.fromEnvironment('DEVICE_SECURITY_SIGN_ALL');

  /// Requests whose path ends with one of these are signed. Extend
  /// progressively (login, OTP, refresh, activation...) once the backend
  /// verifies signatures on them.
  static const List<String> signedPathSuffixes = [
    '/security/test',
  ];

  /// Never signed: they are protected by the attestation itself.
  static const List<String> unsignedPathSuffixes = [
    '/device/challenge',
    '/device/register',
  ];

  /// Diagnostic screen (long press on the version badge).
  static const bool diagnosticEnabled =
      kDebugMode || bool.fromEnvironment('DEVICE_SECURITY_DIAGNOSTIC');

  /// One-line summary printed at startup in debug builds.
  static String describe() => enabled
      ? 'ACTIVÉ | backend ${useMockBackend ? 'SIMULÉ (mock)' : 'RÉEL'} | '
          'signature : ${signAllRequests ? 'TOUTES les requêtes' : signedPathSuffixes.join(', ')} | '
          'diagnostic : ${diagnosticEnabled ? 'oui (appui long sur la version)' : 'non'}'
      : 'DÉSACTIVÉ (lancer avec --dart-define=DEVICE_SECURITY_ENABLED=true) | '
          'diagnostic : ${diagnosticEnabled ? 'oui (appui long sur la version)' : 'non'}';

  static bool shouldSign(String path) {
    if (!enabled) return false;
    if (unsignedPathSuffixes.any(path.endsWith)) return false;
    return signAllRequests || signedPathSuffixes.any(path.endsWith);
  }
}
