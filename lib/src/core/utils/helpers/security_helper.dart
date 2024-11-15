import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SecurityCheck {
  static const platform = MethodChannel('channel');

  static Future<bool> checkSecurity() async {
    try {
      final bool result = await platform.invokeMethod('securityCheck');
      return result;
    } on PlatformException catch (e) {
      return false;
    }
  }
}
