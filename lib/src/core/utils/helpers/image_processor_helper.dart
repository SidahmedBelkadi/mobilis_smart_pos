import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../enums/documents_type.dart';

class ImageHelper {
  static InputImage convertCameraImageToInputImage(
      CameraImage image, CameraController _controller) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());

    final camera = _controller.description;
    final rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
        InputImageRotation.rotation0deg;

    const inputImageFormat = InputImageFormat.yuv420;

    final inputImageData = InputImageMetadata(
      size: imageSize,
      rotation: rotation,
      format: inputImageFormat,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: inputImageData,
    );
  }

  static bool isDocumentRecognized(String text, DocumentsType docType) {
    if (docType == DocumentsType.frontIdCard) {
      final pattern9Digits = RegExp(r'\b\d{9}\b');

      final has9Digits = pattern9Digits.hasMatch(text);

      return has9Digits;
    } else if (docType == DocumentsType.backIdCard) {
      final patternIdDza = RegExp(r'IDDZA');
      final patternName = RegExp(r'Nom');
      final patternSymol = RegExp(r'<<<');

      final hasIdDza = patternIdDza.hasMatch(text);
      final hasName = patternName.hasMatch(text);
      final hasSymbols = patternSymol.hasMatch(text);
      return (hasIdDza && hasName && hasSymbols);
    } else {
      final patternP = RegExp(r'P<');
      final pattern9Digits = RegExp(r'\b\d{9}\b');

      final hasP = patternP.hasMatch(text);
      final has9Digits = pattern9Digits.hasMatch(text);
      return hasP && has9Digits;
    }
  }
}
