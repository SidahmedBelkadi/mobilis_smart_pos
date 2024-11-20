import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../../../config/routing/app_routes.dart';
import '../../../../core/commom/widgets/mrz_overlay.dart';
import '../../../../core/utils/enums/documents_type.dart';
import '../../../../core/utils/helpers/image_processor_helper.dart';
import '../../../../core/utils/ressources/app_colors.dart';
import '../../domain/entities/contract_request_params_entitiy.dart';

class ParentMrzOCRScreen extends StatefulWidget {
  const ParentMrzOCRScreen({
    super.key,
    required this.documentType,
    required this.minorContract,
    this.minorRecto,
    this.minorVerso,
    required this.minorIsPassport,
    required this.parentIsPassport,
  });

  final String documentType;
  final ContractRequestParamsEntitiy minorContract;
  final File? minorRecto;
  final File? minorVerso;
  final bool minorIsPassport;
  final bool parentIsPassport;

  @override
  State<ParentMrzOCRScreen> createState() => _MrzOCRScreenState();
}

class _MrzOCRScreenState extends State<ParentMrzOCRScreen> {
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

    _controller = CameraController(firstCamera, ResolutionPreset.high, enableAudio: false);
    _initializeControllerFuture = _controller!.initialize();
    _controller!.setFocusMode(FocusMode.auto);
    await _initializeControllerFuture;
    if (mounted) {
      setState(() {});
    }

    _controller!.startImageStream(_processCameraImage);
  }

  // bool _isDocumentRecognizedText(String text) {
  //   if (widget.documentType == 'id_card') {
  //     final RegExp documentNumberRegex = RegExp(r"IDDZA([0-9]{9})");
  //     final RegExp idCardRegex = RegExp(r"((\d{6}|[0-9]{2}<<<<))([0-9])([MF])([0-9]{6})");

  //     final documentNumberMatch = documentNumberRegex.firstMatch(text);
  //     if (documentNumberMatch == null) {
  //       return false;
  //     }

  //     final extractedDocumentNumber = documentNumberMatch.group(1);
  //     final dateMatch = idCardRegex.firstMatch(text);

  //     if (dateMatch == null) {
  //       return false;
  //     }

  //     final extractedBirthDate = dateMatch.group(1);
  //     final extractedExpiryDate = dateMatch.group(5);

  //     if (extractedBirthDate == null || extractedExpiryDate == null) {
  //       return false;
  //     }

  //     setState(() {
  //       documentNumber = extractedDocumentNumber!;
  //       birthDate = extractedBirthDate;
  //       expiryDate = extractedExpiryDate;
  //     });

  //     return documentNumber.isNotEmpty && birthDate.isNotEmpty && expiryDate.isNotEmpty;
  //   } else if (widget.documentType == 'passport') {
  //     if (!text.contains('P<')) {
  //       return false;
  //     }

  //     final RegExp passportRegex =
  //         RegExp(r"([A-Z0-9]{9})([0-9])([A-Z]{3})(\d{6}|\d{2}<<<<)([0-9])([MF])([0-9]{6})([0-9])");

  //     // Match the Passport MRZ data
  //     final passportMatch = passportRegex.firstMatch(text);
  //     if (passportMatch == null) {
  //       return false;
  //     }

  //     // Extract document number, birthdate, expiry date, and gender
  //     final extractedDocumentNumber = passportMatch.group(1);
  //     final extractedBirthDate = passportMatch.group(4);
  //     final extractedExpiryDate = passportMatch.group(7);

  //     if (extractedDocumentNumber == null ||
  //         extractedBirthDate == null ||
  //         extractedExpiryDate == null) {
  //       return false;
  //     }

  //     setState(() {
  //       documentNumber = extractedDocumentNumber;
  //       birthDate = extractedBirthDate;
  //       expiryDate = extractedExpiryDate;
  //     });

  //     return documentNumber.isNotEmpty && birthDate.isNotEmpty && expiryDate.isNotEmpty;
  //   }

  //   return false;
  // }

  bool _isDocumentRecognizedText(String text) {
    if (widget.documentType == 'id_card') {
      // Clean the text
      text = text.replaceAll(' ', '').replaceAll(RegExp(r'[^a-zA-Z0-9<]'), '');

      final RegExp documentNumberRegex = RegExp(r"IDDZA([0-9]{9})");
      final RegExp line2Regex = RegExp(r"([0-9<]{6})([0-9]{1})([M|F|X|<]{1})([0-9]{6})");

      // Step 2: Extract Line 1 (Document Number)
      final documentNumberMatch = documentNumberRegex.firstMatch(text);
      if (documentNumberMatch == null) {
        return false;
      }

      final extractedDocumentNumber = documentNumberMatch.group(1);
      debugPrint("================ $extractedDocumentNumber");

      setState(() {
        documentNumber = extractedDocumentNumber!;
      });

      // Step 3: Extract Line 2 (Other Information)
      final matchLine2 = line2Regex.firstMatch(text);
      if (matchLine2 != null) {
        final String birthDateRaw = matchLine2.group(1)!; // Group 1: Birth Date (YYMMDD)
        final String expiryDateRaw = matchLine2.group(4)!; // Group 4: Expiry Date (YYMMDD)
        final String gender = matchLine2.group(3)!; // Group 3: Gender (M/F/X)

        // Validate dates (ensure YYMMDD format)
        if (birthDateRaw.length == 6 && expiryDateRaw.length == 6) {
          setState(() {
            birthDate = birthDateRaw;
            expiryDate = expiryDateRaw;
          });

          debugPrint("============== Extracted Birth Date: $birthDate");
          debugPrint("============== Extracted Expiry Date: $expiryDate");
          debugPrint("=============== Extracted Gender: $gender");

          return true;
        } else {
          debugPrint("Invalid Date Format in Line 2");
          return false;
        }
      } else {
        debugPrint("Line 2 Regex did not match");
        return false;
      }
    } else if (widget.documentType == 'passport') {
      final RegExp passportRegex =
          RegExp(r"([A-Z0-9]{9})([0-9])([A-Z]{3})(\d{6}|\d{2}<<<<)([0-9])([MF])([0-9]{6})([0-9])");

      // Match the Passport MRZ data
      final passportMatch = passportRegex.firstMatch(text);
      if (passportMatch == null) {
        return false;
      }

      // Extract document number, birthdate, expiry date, and gender
      final extractedDocumentNumber = passportMatch.group(1);
      final extractedBirthDate = passportMatch.group(4);
      final extractedExpiryDate = passportMatch.group(7);

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

      return documentNumber.isNotEmpty && birthDate.isNotEmpty && expiryDate.isNotEmpty;
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
      final inputImage = ImageHelper.convertCameraImageToInputImage(image, _controller!);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      debugPrint(recognizedText.text);

      final isDocumentRecognized = _isDocumentRecognizedText(recognizedText.text);

      if (mounted) {
        setState(() {
          _isDocumentRecognized = isDocumentRecognized;
        });

        // Navigate to the NFC screen only once
        if (_isDocumentRecognized && !_hasNavigated) {
          _hasNavigated = true; // Prevent further navigation
          await Future.delayed(const Duration(microseconds: 1500));
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
    Navigator.of(context).pushReplacementNamed(Routes.parentMrzOcrDetails, arguments: {
      'documentNumber': documentNumber,
      'dateOfBirth': birthDate,
      'dateOfExpiry': expiryDate,
      'docType': widget.documentType,
      'documentType': widget.minorIsPassport ? 'passport' : 'id_card',
      'minorContract': widget.minorContract,
      'minorRecto': widget.minorRecto,
      'minorVerso': widget.minorVerso,
      'minorIsPassport': widget.minorIsPassport,
      'parentIsPassport': widget.parentIsPassport,
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _textRecognizer = TextRecognizer();
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
