import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:screen_protector/screen_protector.dart';

class ScreenshotService {
  static const platform = MethodChannel('otp_receiver');

  static Future<void> disableScreenshots() async {
    try {
      await platform.invokeMethod('disableScreenshots');
    } on PlatformException catch (e) {
      debugPrint("$e");
    }
  }

  static Future<void> enableScreenshots() async {
    try {
      await platform.invokeMethod('enableScreenshots');
    } on PlatformException catch (e) {
      debugPrint("$e");
    }
  }

  static Future<void> preventScreenshotOn() async {
    await ScreenProtector.preventScreenshotOn();
  }

  static Future<void> preventScreenshotOff() async {
    await ScreenProtector.preventScreenshotOff();
  }
}
