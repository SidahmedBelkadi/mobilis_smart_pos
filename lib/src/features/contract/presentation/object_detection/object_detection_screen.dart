import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/utils/enums/documents_type.dart';

class ObjectDetectionScreen extends StatefulWidget {
  const ObjectDetectionScreen({
    super.key,
    required this.onPictureTaken,
    required this.documentsType,
  });

  final Function(File) onPictureTaken;
  final DocumentsType documentsType;

  @override
  ObjectDetectionScreenState createState() => ObjectDetectionScreenState();
}

class ObjectDetectionScreenState extends State<ObjectDetectionScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isDocumentRecognized = false;
  bool _isProcessing = false;
  bool _pictureTaken = false;
  late TextRecognizer _textRecognizer;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _textRecognizer = TextRecognizer();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _controller = CameraController(
      firstCamera,
      enableAudio: false,
      ResolutionPreset.high,
    );

    _initializeControllerFuture = _controller!.initialize();
    await _initializeControllerFuture;
    if (mounted) {
      setState(() {});
    }

    _controller!.startImageStream(_processCameraImage);
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing || _pictureTaken) return;
    _isProcessing = true;

    try {
      final inputImage = _convertCameraImageToInputImage(image);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      final isDocumentRecognized = _isDocumentRecognizedText(recognizedText.text);

      if (mounted) {
        setState(() {
          _isDocumentRecognized = isDocumentRecognized;
        });
      }
    } catch (e) {
      debugPrint('Error processing image: $e');
    } finally {
      _isProcessing = false;
    }
  }

  InputImage _convertCameraImageToInputImage(CameraImage image) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());

    final camera = _controller!.description;
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

  bool _isDocumentRecognizedText(String text) {
    if (widget.documentsType == DocumentsType.frontIdCard) {
      //final pattern18Digits = RegExp(r'\b\d{18}\b'); // Pattern to match exactly 18-digit numbers
      final pattern9Digits = RegExp(r'\b\d{9}\b'); // Pattern to match exactly 9-digit numbers

      //final has18Digits = pattern18Digits.hasMatch(text);
      final has9Digits = pattern9Digits.hasMatch(text);

      //   return (has18Digits && has9Digits);
      return has9Digits;
    } else if (widget.documentsType == DocumentsType.backIdCard) {
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

  Future<void> _takePicture() async {
    if (await _requestPermissions()) {
      try {
        await Future.delayed(const Duration(milliseconds: 700));
        await _initializeControllerFuture;
        final image = await _controller!.takePicture();

        // Get the path to the document directory
        final directory = await getApplicationDocumentsDirectory();
        final imagePath = join(directory.path, '${DateTime.now()}.png');

        // Crop the image
        final croppedImage = await _cropImage(File(image.path));

        // Save the cropped image to the local file system
        final savedImage = await croppedImage.copy(imagePath);

        // Call the callback with the saved image
        widget.onPictureTaken(savedImage);

        // Check if the image is a photocopy
        final isPhotocopy = await _checkIfPhotocopy(savedImage);

        // Navigate back to home screen
        if (mounted) {
          Navigator.of(context).pop();
        }

        if (isPhotocopy) {
          // Show a message or take an appropriate action
          debugPrint('The document appears to be a photocopy.');
        } else {
          // Show a message or take an appropriate action
          debugPrint('The document appears to be an original.');
        }
      } catch (e) {
        debugPrint('Error taking picture: $e');
      }
    }
  }

  Future<File> _cropImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final img.Image? originalImage = img.decodeImage(Uint8List.fromList(bytes));

    if (originalImage == null) {
      throw Exception("Unable to decode image");
    }

    const double padding = 20.0;
    final double rectWidth = originalImage.width - 2 * padding;
    final double rectHeight = originalImage.height / 3;
    const double x = padding;
    final double y = (originalImage.height - rectHeight) / 2;

    // Crop the image
    final img.Image croppedImage = img.copyCrop(
      originalImage,
      x: x.toInt(),
      y: y.toInt(),
      width: rectWidth.toInt(),
      height: rectHeight.toInt(),
    );

    // Encode the cropped image back to a file
    final croppedFilePath =
        join((await getTemporaryDirectory()).path, '${DateTime.now()}_cropped.png');
    final croppedFile = File(croppedFilePath);
    await croppedFile.writeAsBytes(img.encodePng(croppedImage));

    return croppedFile;
  }

  Future<bool> _requestPermissions() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<bool> _checkIfPhotocopy(File imageFile) async {
    // Implement your liveness detection logic here
    // For example, analyze texture patterns, reflectance properties, etc.
    // Return true if it's a photocopy, false if it's an original document.
    return false; // Placeholder implementation
  }

  @override
  void dispose() {
    _controller?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(_controller!),
                CustomPaint(
                  painter: RectangleOverlayPainter(isDocumentRecognized: _isDocumentRecognized),
                ),
                if (_isDocumentRecognized)
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: FloatingActionButton(
                      backgroundColor: Colors.green,
                      onPressed: _takePicture,
                      child: const Icon(Icons.camera),
                    ),
                  ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

class RectangleOverlayPainter extends CustomPainter {
  final bool isDocumentRecognized;

  RectangleOverlayPainter({required this.isDocumentRecognized});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDocumentRecognized ? Colors.green : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    const double padding = 20.0;
    final double rectWidth = size.width - 2 * padding;
    final double rectHeight = size.height / 3;
    const double x = padding;
    final double y = (size.height - rectHeight) / 2;
    const double borderRadius = 20.0;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, rectWidth, rectHeight),
      const Radius.circular(borderRadius),
    );

    // Draw the overlay with a hole for the rectangle
    final path = Path.combine(
      PathOperation.difference,
      Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
      Path()..addRRect(rect),
    );

    canvas.drawPath(path, Paint()..color = Colors.black.withOpacity(0.8));

    // Draw the colored rectangle border
    canvas.drawRRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
