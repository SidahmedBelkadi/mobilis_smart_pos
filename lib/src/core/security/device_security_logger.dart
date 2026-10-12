import 'package:flutter/foundation.dart';

/// Debug-only traces of the device security flow. Filter the console on
/// "[DeviceSecurity]". Nothing is printed in profile/release builds.
void securityLog(String message) {
  if (kDebugMode) debugPrint('🔐 [DeviceSecurity] $message');
}
