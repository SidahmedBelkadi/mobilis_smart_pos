import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CustomCameraView extends StatefulWidget {
  final Function(File) onImageCaptured;
  final bool isRecto;

  const CustomCameraView({required this.onImageCaptured, required this.isRecto, Key? key})
      : super(key: key);

  @override
  _CustomCameraViewState createState() => _CustomCameraViewState();
}

class _CustomCameraViewState extends State<CustomCameraView> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  late List<CameraDescription> cameras;
  bool isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    cameras = await availableCameras();
    _controller = CameraController(cameras[0], ResolutionPreset.high);
    _initializeControllerFuture = _controller.initialize();
    await _initializeControllerFuture;
    setState(() {
      isCameraInitialized = true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();
      widget.onImageCaptured(File(image.path));
    } catch (e) {
      debugPrint("========= $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isCameraInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        CameraPreview(_controller),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton(
              onPressed: _captureImage,
              child: const Text('Capture'),
            ),
          ),
        ),
        Center(
          child: Container(
            width: 300,
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red, width: 2.0),
            ),
          ),
        ),
      ],
    );
  }
}
