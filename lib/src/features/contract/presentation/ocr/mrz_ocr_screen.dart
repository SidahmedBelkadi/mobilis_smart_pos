import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:mobilis_smart_pos/src/core/commom/widgets/mrz_overlay.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/image_processor_helper.dart';
import 'package:mobilis_smart_pos/src/services/screenshot_service.dart';

import '../../../../config/routing/app_routes.dart';
import '../../../../core/utils/enums/documents_type.dart';
import '../../../../core/utils/ressources/app_colors.dart';

class MrzOCRScreen extends StatefulWidget {
  const MrzOCRScreen({
    super.key,
    required this.documentType,
  });

  final String documentType;

  @override
  State<MrzOCRScreen> createState() => _MrzOCRScreenState();
}

class _MrzOCRScreenState extends State<MrzOCRScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  late TextRecognizer _textRecognizer;
  bool _isDocumentRecognized = false;
  bool _isProcessing = false;
  bool _hasNavigated = false;
  int _frameCount = 0;
  final int _frameThrottleRate = 3;
  late String documentNumber;
  late String birthDate;
  late String expiryDate;

  // Torch control flag
  bool _isTorchEnabled = false;

  Future<void> _toggleTorch() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    if (_isTorchEnabled) {
      await _controller!.setFlashMode(FlashMode.off);
    } else {
      await _controller!.setFlashMode(FlashMode.torch);
    }

    setState(() {
      _isTorchEnabled = !_isTorchEnabled;
    });
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _controller = CameraController(firstCamera, ResolutionPreset.high,
        enableAudio: false);
    _controller!.setFocusMode(FocusMode.auto);
    _controller!.setExposureMode(ExposureMode.auto);

    _initializeControllerFuture = _controller!.initialize();
    await _initializeControllerFuture;
    if (mounted) {
      setState(() {});
    }

    _controller!.startImageStream(_processCameraImage);
  }

  bool _isDocumentRecognizedText(String text) {
    if (widget.documentType == 'id_card') {
      final RegExp documentNumberRegex = RegExp(r"IDDZA([0-9]{9})");
      final RegExp idCardRegex =
          RegExp(r"((\d{6}|[0-9]{2}<<<<))([0-9])([MF])([0-9]{6})");

      final documentNumberMatch = documentNumberRegex.firstMatch(text);
      if (documentNumberMatch == null) {
        return false;
      }

      final extractedDocumentNumber = documentNumberMatch.group(1);
      final dateMatch = idCardRegex.firstMatch(text);

      if (dateMatch == null) {
        return false;
      }

      final extractedBirthDate = dateMatch.group(1);
      final gender = dateMatch.group(3);
      final extractedExpiryDate = dateMatch.group(5);

      if (extractedBirthDate == null || extractedExpiryDate == null) {
        return false;
      }

      setState(() {
        documentNumber = extractedDocumentNumber!;
        birthDate = extractedBirthDate;
        expiryDate = extractedExpiryDate;
      });

      return documentNumber.isNotEmpty &&
          birthDate.isNotEmpty &&
          expiryDate.isNotEmpty;
    } else if (widget.documentType == 'passport') {
      if (!text.contains('P<')) {
        return false;
      }

      final RegExp passportRegex = RegExp(
          r"([A-Z0-9]{9})([0-9])([A-Z]{3})(\d{6}|\d{2}<<<<)([0-9])([MF])([0-9]{6})([0-9])");

      // Match the Passport MRZ data
      final passportMatch = passportRegex.firstMatch(text);
      if (passportMatch == null) {
        return false;
      }

      // Extract document number, birthdate, expiry date, and gender
      final extractedDocumentNumber = passportMatch.group(1);
      final extractedBirthDate = passportMatch.group(4);
      final extractedExpiryDate = passportMatch.group(7);
      final gender = passportMatch.group(6);

      if (extractedDocumentNumber == null ||
          extractedBirthDate == null ||
          extractedExpiryDate == null) {
        return false;
      }

      setState(() {
        documentNumber = extractedDocumentNumber;
        birthDate = extractedBirthDate;
        expiryDate = extractedExpiryDate;
      });

      return documentNumber.isNotEmpty &&
          birthDate.isNotEmpty &&
          expiryDate.isNotEmpty;
    }

    return false;
  }

  Future<void> _processCameraImage(CameraImage image) async {
    _frameCount++;

    // Skip frames to implement frame throttling
    if (_isProcessing || _frameCount % _frameThrottleRate != 0) {
      return;
    }

    _isProcessing = true;
    try {
      final inputImage =
          ImageHelper.convertCameraImageToInputImage(image, _controller!);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      final isDocumentRecognized =
          _isDocumentRecognizedText(recognizedText.text);

      if (mounted) {
        setState(() {
          _isDocumentRecognized = isDocumentRecognized;
        });

        // Navigate to the NFC screen only once
        if (_isDocumentRecognized && !_hasNavigated) {
          _hasNavigated = true; // Prevent further navigation
          await Future.delayed(const Duration(milliseconds: 500));
          _navigateToMRZDetails();
        }
      }
    } catch (e) {
      debugPrint('Error processing image: $e');
    } finally {
      _isProcessing = false;
    }
  }

  void _navigateToMRZDetails() {
    Navigator.of(context).pushReplacementNamed(Routes.mrzDetails, arguments: {
      'documentNumber': documentNumber,
      'dateOfBirth': birthDate,
      'dateOfExpiry': expiryDate,
      'docType': widget.documentType,
    });
  }

  @override
  void initState() {
    ScreenshotService.preventScreenshotOn();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    super.initState();
    _initializeCamera();
    _textRecognizer = TextRecognizer();
  }

  @override
  void dispose() {
    ScreenshotService.preventScreenshotOff();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

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
          if (snapshot.connectionState == ConnectionState.done &&
              _controller != null) {
            return Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(_controller!),
                CustomPaint(
                  painter: MRZOverlay(
                    isDocumentRecognized: _isDocumentRecognized,
                    documentsType: widget.documentType == "passport"
                        ? DocumentsType.passport
                        : DocumentsType.frontIdCard,
                  ),
                ),
                Positioned(
                  top: 25,
                  right: 20,
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.secondary,
                      ),
                      child: Icon(
                        _isTorchEnabled ? Icons.flash_on : Icons.flash_off,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    onPressed: _toggleTorch,
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
