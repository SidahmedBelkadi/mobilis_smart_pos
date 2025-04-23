import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:edge_detection_plus/edge_detection_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

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

      // ML Kit returned result, but empty — fallback
      return await _useEdgeDetectionFallback();
    } on PlatformException catch (e) {
      if (e.code == "SCAN_CANCELLED") {
        debugPrint("=========== User cancelled ML Kit scanner. No fallback.");
        return [];
      }

      debugPrint("=========== ML Kit scanner failed, using fallback: ${e.message}");
      return await _useEdgeDetectionFallback();
    } catch (e) {
      debugPrint("=========== Unexpected scanner error, using fallback: $e");
      return await _useEdgeDetectionFallback();
    }
  }

  static Future<List<String>> _useEdgeDetectionFallback() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = p.join(
        dir.path,
        '${DateTime.now().millisecondsSinceEpoch}.jpeg',
      );

      final success = await EdgeDetectionPlus.detectEdge(
        filePath,
        canUseGallery: false,
        androidScanTitle: 'Numériser un document',
        androidCropTitle: 'Rogner',
        androidCropBlackWhiteTitle: 'Noir et blanc',
        androidCropReset: 'Réinitialiser',
      );

      if (success && File(filePath).existsSync()) {
        debugPrint("=========== EdgeDetection fallback success: $filePath");
        return [filePath];
      } else {
        debugPrint("=========== EdgeDetection fallback failed or cancelled.");
        return [];
      }
    } catch (e) {
      debugPrint("=========== EdgeDetection fallback error: $e");
      return [];
    }
  }
}
