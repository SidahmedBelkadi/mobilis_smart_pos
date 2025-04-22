import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NativeDocumentScanner {
  static const MethodChannel _channel = MethodChannel('channel');

  static Future<List<String>> getPictures() async {
    try {
      final result = await _channel.invokeMethod<Map>('startDocumentScanner');

      debugPrint("=========== NativeDocumentScanner result: $result");

      if (result != null) {
        if (result['imageUris'] != null) {
          final List<dynamic> uris = result['imageUris'];
          return uris
              .map((uri) => Uri.parse(uri).toFilePath())
              .where((path) => File(path).existsSync())
              .toList();
        } else if (result['imageUri'] != null) {
          final path = Uri.parse(result['imageUri']).toFilePath();
          if (File(path).existsSync()) {
            return [path];
          }
        }
      }

      return [];
    } on PlatformException catch (e) {
      debugPrint("=========== NativeDocumentScanner failed: ${e.message}");
      return [];
    }
  }
}
