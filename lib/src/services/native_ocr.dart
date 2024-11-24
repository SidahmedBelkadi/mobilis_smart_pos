import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NativeOCR {
  static const MethodChannel _channel = MethodChannel('channel');

  // Method to start OCR
  static Future<Map<String, String>?> startOCR({required String docType}) async {
    try {
      final result = await _channel.invokeMethod<Map>('startOCR', {'documentType': docType});
      debugPrint("===================== result $result");
      if (result != null) {
        return Map<String, String>.from(result);
      }
    } catch (e) {
      debugPrint("Error starting OCR: $e");
    }
    return null;
  }
}
