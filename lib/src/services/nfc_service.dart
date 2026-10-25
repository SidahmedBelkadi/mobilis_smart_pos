import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NFCService {
  static const platform = MethodChannel('channel');

  static Future<bool> isNfcEnabled() async {
    return await platform.invokeMethod('isNfcEnabled');
  }

  Future<Map<String, dynamic>> readNfc(
      String documentType,
      String documentNumber,
      String dateOfBirth,
      String dateOfExpiry,
      bool exractFacialImage,
      bool extrcatSignature) async {
    try {
      final String result = await platform.invokeMethod('readNfc', {
        'documentType': documentType,
        'documentNumber': documentNumber,
        'dateOfBirth': dateOfBirth,
        'dateOfExpiry': dateOfExpiry,
        'exractFacialImage': exractFacialImage,
        'extrcatSignature': extrcatSignature,
      });
      return Map<String, dynamic>.from(json.decode(result));
    } on PlatformException catch (e) {
      debugPrint("=================== Error starting NFC scan: ${e.code} ${e.message}");
      // code: BAC_FAILED, DOCUMENT_NOT_AUTHENTIC, NFC_READ_ERROR or CANCELLED
      return {'error': 'Failed to start NFC scan: ${e.message}', 'code': e.code};
    }
  }

  /// Ends the pending [readNfc] session (its result becomes CANCELLED).
  static Future<void> cancel() async {
    try {
      await platform.invokeMethod('cancelNfc');
    } on PlatformException catch (_) {}
  }
}
