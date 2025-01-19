import 'dart:io';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:mobilis_smart_pos/src/core/utils/enums/documents_type.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/app_localization_helper.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/toast_helper.dart';

class RASD {
  RASD._();

  static Future<File?> captureDocument({
    required TextRecognizer recognizer,
    required DocumentsType docType,
    required BuildContext context,
  }) async {
    final imagesPath =
        await CunningDocumentScanner.getPictures(noOfPages: 1, isGalleryImportAllowed: false);

    if (imagesPath != null && imagesPath.isNotEmpty) {
      File file = File(imagesPath[0]);

      final inputImage = InputImage.fromFile(file);
      final recognizedText = await recognizer.processImage(inputImage);

      debugPrint("===== Recognized Text : \n ${recognizedText.text}");

      final isValid = _isDocumentRecognized(recognizedText.text, docType);
      if (isValid) {
        return file;
      } else {
        // ignore: use_build_context_synchronously
        _showErrorMessage(docType, context);
      }
    }
    return null;
  }

  static void extractAndStoreData({
    required String text,
    required DocumentsType documentType,
    required TextEditingController nameController,
    required TextEditingController dateOfBirthController,
    required TextEditingController placeOfBirthController,
    required TextEditingController documentNumberController,
    required TextEditingController fatherNameController,
    required TextEditingController motherNameController,
    required TextEditingController domicilioController,
    required TextEditingController fechaDeExpedicionController,
    required Function(String?) updateSexo,
  }) {
    if (documentType == DocumentsType.rasdFrontIdCard) {
      final namePattern = RegExp(r'NOMBRE\s+(.+?)\n');
      final birthDatePattern = RegExp(r'FECHA DE NACIMIENTO\s+(\d{2}/\d{2}/\d{4})');
      final placeOfBirthPattern = RegExp(r'\bW\.\s+([^\n]+)');
      final lugarNacimientoPattern = RegExp(r'LUGAR DE NACIMIENTO\s+([^\n]+)');
      final documentNumberPattern = RegExp(r'(\d{8,})');

      final nameMatch = namePattern.firstMatch(text);
      if (nameMatch != null) nameController.text = nameMatch.group(1)!.trim();

      final birthDateMatch = birthDatePattern.firstMatch(text);
      if (birthDateMatch != null) dateOfBirthController.text = birthDateMatch.group(1)!.trim();

      final placeOfBirth = placeOfBirthPattern.firstMatch(text)?.group(1) ??
          lugarNacimientoPattern.firstMatch(text)?.group(1);
      if (placeOfBirth != null) placeOfBirthController.text = placeOfBirth.trim();

      final documentNumberMatch = documentNumberPattern.firstMatch(text);
      if (documentNumberMatch != null) {
        documentNumberController.text = documentNumberMatch.group(1)!.trim();
      }
    } else if (documentType == DocumentsType.rasdBackIdCard) {
      final sexoPattern = RegExp(r'SEXO\s+([MF])');
      final fatherNamePattern = RegExp(r'NOMBRE DEL PADRE\s+(.+?)\n');
      final motherNamePattern = RegExp(r'NOMBRE DE LA MADRE\s+(.+?)\n');
      final domicilioPattern = RegExp(r'DOMICILIO\s+(.+?)\n');
      final datePattern = RegExp(r'(\d{2}/\d{2}/\d{4})');

      final sexoMatch = sexoPattern.firstMatch(text);
      updateSexo(sexoMatch?.group(1)?.trim());

      final fatherNameMatch = fatherNamePattern.firstMatch(text);
      if (fatherNameMatch != null) fatherNameController.text = fatherNameMatch.group(1)!.trim();

      final motherNameMatch = motherNamePattern.firstMatch(text);
      if (motherNameMatch != null) motherNameController.text = motherNameMatch.group(1)!.trim();

      final domicilioMatch = domicilioPattern.firstMatch(text);
      if (domicilioMatch != null) {
        domicilioController.text = domicilioMatch.group(1)!.trim();
      }

      final expiryDateMatch = datePattern.firstMatch(text);
      if (expiryDateMatch != null) {
        fechaDeExpedicionController.text = expiryDateMatch.group(1)!.trim();
      }
    }
  }

  static bool _isDocumentRecognized(String text, DocumentsType docType) {
    final normalizedText = text.toLowerCase().replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ');

    if (docType == DocumentsType.rasdFrontIdCard) {
      final patterns = [
        RegExp(r'republica', caseSensitive: false),
        RegExp(r'árabe saharaui democrática', caseSensitive: false),
        RegExp(r'\b\d{8,9}\b'),
      ];

      int matchCount = patterns.where((pattern) => pattern.hasMatch(normalizedText)).length;

      return matchCount >= 2;
    } else if (docType == DocumentsType.rasdBackIdCard) {
      final patterns = [
        RegExp(r'ministerio del interior', caseSensitive: false),
        RegExp(r'sexo', caseSensitive: false),
        RegExp(r'(\d{2}/\d{2}/\d{4})'),
      ];

      int matchCount = patterns.where((pattern) => pattern.hasMatch(normalizedText)).length;

      return matchCount >= 2;
    }

    return false;
  }

  static void _showErrorMessage(DocumentsType docType, BuildContext context) {
    String message;
    switch (docType) {
      case DocumentsType.rasdFrontIdCard:
        message = "incorrect_front_id_card_image".tr(context);
        break;
      case DocumentsType.rasdBackIdCard:
        message = "incorrect_back_id_card_image".tr(context);
        break;
      default:
        message = "incorrect_image".tr(context);
        break;
    }
    AppToasts.showWarningToast(message: message, context: context);
  }
}
