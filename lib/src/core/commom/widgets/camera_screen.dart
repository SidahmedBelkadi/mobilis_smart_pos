import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../../../services/screenshot_service.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraScreen extends StatefulWidget {
  final Function(File) onPictureTaken;

  const CameraScreen({super.key, required this.onPictureTaken});

  @override
  CameraScreenState createState() => CameraScreenState();
}

class CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    ScreenshotService.preventScreenshotOn();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _controller = CameraController(
      firstCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    _controller?.setFocusMode(FocusMode.auto);
    _controller?.setExposureMode(ExposureMode.auto);

    _initializeControllerFuture = _controller!.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _takePicture(BuildContext context) async {
    if (await _requestPermissions()) {
      try {
        await _initializeControllerFuture;
        final image = await _controller!.takePicture();

        // Get the path to the document directory
        final directory = await getApplicationDocumentsDirectory();
        final imagePath = join(directory.path, '${DateTime.now()}.jpg');

        // Crop the image
        final croppedImage = await _cropImage(File(image.path));

        // Save the cropped image to the local file system
        final savedImage = await croppedImage.copy(imagePath);

        // Call the callback with the saved image
        widget.onPictureTaken(savedImage);

        // Delete the original and cropped image files after use
        await File(image.path).delete(); // Delete the original image
        await croppedImage.delete(); // Delete the cropped image

        // Navigate back to home screen
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        debugPrint('================== Error: $e');
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

  @override
  void dispose() {
    _controller?.dispose();
    ScreenshotService.preventScreenshotOff();
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
                  painter: RectangleOverlayPainter(),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 50.0),
                    child: FloatingActionButton(
                      onPressed: () => _takePicture(context),
                      child: const Icon(Icons.camera_alt),
                    ),
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
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    //final overlayPaint = Paint()
    // ..color = Colors.black.withOpacity(0)
    // ..style = PaintingStyle.fill;

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

    canvas.drawPath(path, paint);

    // Draw the green rectangle border
    canvas.drawRRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
