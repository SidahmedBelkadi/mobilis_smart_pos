import 'dart:io';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:insta_image_viewer/insta_image_viewer.dart';
import 'package:mobilis_smart_pos/src/core/commom/widgets/app_text_form_field.dart';
import 'package:mobilis_smart_pos/src/core/commom/widgets/custom_app_bar.dart';
import 'package:mobilis_smart_pos/src/core/utils/enums/documents_type.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/app_localization_helper.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/media_query_values.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/toast_helper.dart';
import 'package:mobilis_smart_pos/src/features/profile/presentation/widget/upload_image_field.dart';

class RasdTest extends StatefulWidget {
  const RasdTest({super.key});

  @override
  State<RasdTest> createState() => _RasdTestState();
}

class _RasdTestState extends State<RasdTest> {
  late TextRecognizer _textRecognizer;

  File? rectoImage;
  File? versoImage;
  bool isCaptureDone = false;

  // Separate variables for storing extracted data
  String name = '';
  String dateOfBirth = '';
  String placeOfBirth = '';
  String documentNumber = '';
  String sexo = '';
  String fatherName = '';
  String motherName = '';
  String domicilio = '';
  String fechaDeExpedicion = '';

  @override
  void initState() {
    _textRecognizer = TextRecognizer();
    super.initState();
  }

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "RASD"),
      body: Container(
        padding: EdgeInsets.all(24.sp),
        height: context.height,
        width: context.width,
        child: isCaptureDone
            ? SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Extracted Informations",
                      style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16.sp),
                    AppTextFormField(
                      enabled: false,
                      label: 'Name',
                      textEditingController: TextEditingController(text: name),
                    ),
                    AppTextFormField(
                      enabled: false,
                      label: 'Date of Birth',
                      textEditingController: TextEditingController(text: dateOfBirth),
                    ),
                    AppTextFormField(
                      enabled: false,
                      label: 'Place of Birth',
                      textEditingController: TextEditingController(text: placeOfBirth),
                    ),
                    AppTextFormField(
                      enabled: false,
                      label: 'Document Number',
                      textEditingController: TextEditingController(text: documentNumber),
                    ),
                    AppTextFormField(
                      enabled: false,
                      label: 'Sexo',
                      textEditingController: TextEditingController(text: sexo),
                    ),
                    AppTextFormField(
                      enabled: false,
                      label: 'Father\'s Name',
                      textEditingController: TextEditingController(text: fatherName),
                    ),
                    AppTextFormField(
                      enabled: false,
                      label: 'Mother\'s Name',
                      textEditingController: TextEditingController(text: motherName),
                    ),
                    AppTextFormField(
                      enabled: false,
                      label: 'Domicilio',
                      textEditingController: TextEditingController(text: domicilio),
                    ),
                    AppTextFormField(
                      enabled: false,
                      label: 'Expiry date',
                      textEditingController: TextEditingController(text: fechaDeExpedicion),
                    ),
                    SizedBox(height: 16.sp),
                    Text(
                      "Captured Images",
                      style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16.sp),
                    rectoImage != null
                        ? InstaImageViewer(
                            child: Image.file(
                              rectoImage!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Text("Front Image not captured"),
                    SizedBox(height: 16.sp),
                    versoImage != null
                        ? InstaImageViewer(
                            child: Image.file(
                              versoImage!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Text("Back Image not captured"),
                  ],
                ),
              )
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    rectoImage != null
                        ? InstaImageViewer(child: Image.file(rectoImage!))
                        : UploadImageField(
                            icon: FontAwesomeIcons.camera,
                            label: "recto".tr(context),
                            onTap: () async {
                              final result = await captureDocument(
                                recognizer: _textRecognizer,
                                docType: DocumentsType.rasdFrontIdCard,
                                context: context,
                              );
                              if (result != null) {
                                setState(() {
                                  rectoImage = result;
                                });
                              }
                            },
                          ),
                    SizedBox(height: 36.sp),
                    versoImage != null
                        ? InstaImageViewer(child: Image.file(versoImage!))
                        : UploadImageField(
                            icon: FontAwesomeIcons.camera,
                            label: "verso".tr(context),
                            onTap: () async {
                              final result = await captureDocument(
                                recognizer: _textRecognizer,
                                docType: DocumentsType.rasdBackIdCard,
                                context: context,
                              );
                              if (result != null) {
                                setState(() {
                                  versoImage = result;
                                  isCaptureDone = true;
                                });
                              }
                            },
                          )
                  ],
                ),
              ),
      ),
    );
  }

  Future<File?> captureDocument({
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

      // Validate the document
      final isValid = _isDocumentRecognized(recognizedText.text, docType);
      if (isValid) {
        // Extract data if valid
        extractAndStoreData(recognizedText.text, docType);

        AppToasts.showSuccessToast(
            message: "Document validated and data extracted successfully!", context: context);
        return file;
      } else {
        // Show error message if not valid
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
    return null;
  }

  void extractAndStoreData(String text, DocumentsType documentType) {
    if (documentType == DocumentsType.rasdFrontIdCard) {
      // Extract data for the front of the ID card
      final namePattern = RegExp(r'NOMBRE\s+(.+?)\n');
      final birthDatePattern = RegExp(r'FECHA DE NACIMIENTO\s+(\d{2}/\d{2}/\d{4})');
      final placeOfBirthPattern = RegExp(r'\bW\.\s+([^\n]+)'); // Matches 'W.' followed by text
      final documentNumberPattern = RegExp(r'(\d{8,})'); // Look for 8+ digit numbers

      final nameMatch = namePattern.firstMatch(text);
      if (nameMatch != null) name = nameMatch.group(1)!.trim();

      final birthDateMatch = birthDatePattern.firstMatch(text);
      if (birthDateMatch != null) dateOfBirth = birthDateMatch.group(1)!.trim();

      final placeOfBirthMatch = placeOfBirthPattern.firstMatch(text);
      if (placeOfBirthMatch != null) placeOfBirth = placeOfBirthMatch.group(0)!.trim();

      final documentNumberMatch = documentNumberPattern.firstMatch(text);
      if (documentNumberMatch != null) documentNumber = documentNumberMatch.group(1)!.trim();

      debugPrint(
          "Front Data Extracted: Name=$name, DOB=$dateOfBirth, Place=$placeOfBirth, DocNumber=$documentNumber");
    } else if (documentType == DocumentsType.rasdBackIdCard) {
      // Back ID Card Extraction

      final sexoPattern = RegExp(r'SEXO\s+([MF])');
      final fatherNamePattern = RegExp(r'NOMBRE DEL PADRE\s+(.+?)\n');
      final motherNamePattern = RegExp(r'NOMBRE DE LA MADRE\s+(.+?)\n');
      final domicilioPattern = RegExp(r'DOMICILIO\s+(.+?)\n');
      final datePattern = RegExp(r'(\d{2}/\d{2}/\d{4})'); // Match any date in DD/MM/YYYY format

      final sexoMatch = sexoPattern.firstMatch(text);
      if (sexoMatch != null) sexo = sexoMatch.group(1)!.trim();

      final fatherNameMatch = fatherNamePattern.firstMatch(text);
      if (fatherNameMatch != null) fatherName = fatherNameMatch.group(1)!.trim();

      final motherNameMatch = motherNamePattern.firstMatch(text);
      if (motherNameMatch != null) motherName = motherNameMatch.group(1)!.trim();

      final domicilioMatch = domicilioPattern.firstMatch(text);
      if (domicilioMatch != null) domicilio = domicilioMatch.group(1)!.trim();

      // Simplified logic: Use the first date found on the back of the ID
      final expiryDateMatch = datePattern.firstMatch(text);
      if (expiryDateMatch != null) fechaDeExpedicion = expiryDateMatch.group(1)!.trim();

      debugPrint(
          "Back Data Extracted: Sexo=$sexo, Father=$fatherName, Mother=$motherName, Domicilio=$domicilio, ExpiryDate=$fechaDeExpedicion");
    }
  }

  bool _isDocumentRecognized(String text, DocumentsType docType) {
    if (docType == DocumentsType.rasdFrontIdCard) {
      final pattern9Digits = RegExp(r'\b\d{8}\b');
      final has9Digits = pattern9Digits.hasMatch(text);
      final patternIdRepublica = RegExp(r'REPUBLICA', caseSensitive: false);
      final hasRepublica = patternIdRepublica.hasMatch(text);
      return has9Digits && hasRepublica;
    } else if (docType == DocumentsType.rasdBackIdCard) {
      final patternIdMinisterio = RegExp(r'ministerio del interior', caseSensitive: false);
      return patternIdMinisterio.hasMatch(text);
    }
    return false;
  }
}
