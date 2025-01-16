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
import 'package:mobilis_smart_pos/src/core/utils/ressources/app_colors.dart';
import 'package:mobilis_smart_pos/src/features/profile/presentation/widget/upload_image_field.dart';

class RasdOcrScreen extends StatefulWidget {
  const RasdOcrScreen({super.key});

  @override
  State<RasdOcrScreen> createState() => _RasdOcrScreenState();
}

class _RasdOcrScreenState extends State<RasdOcrScreen> {
  late TextRecognizer _textRecognizer;

  File? rectoImage;
  File? versoImage;
  bool isCaptureDone = false;
  bool isConfirmed = false;

  // TextEditingControllers for editable fields
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dateOfBirthController = TextEditingController();
  final TextEditingController placeOfBirthController = TextEditingController();
  final TextEditingController documentNumberController = TextEditingController();
  final TextEditingController sexoController = TextEditingController();
  final TextEditingController fatherNameController = TextEditingController();
  final TextEditingController motherNameController = TextEditingController();
  final TextEditingController domicilioController = TextEditingController();
  final TextEditingController fechaDeExpedicionController = TextEditingController();

  // Dropdown for Sexo
  String? selectedSexo;
  String? selectedPlaceOfBirth;

  // Predefined list of valid Place of Birth values
  final List<String> validPlacesOfBirth = ['LAIUN', 'AOUSERD', 'SMARA', 'DAJLA', 'BOJDUR'];

  @override
  void initState() {
    _textRecognizer = TextRecognizer();
    super.initState();
  }

  @override
  void dispose() {
    _textRecognizer.close();
    nameController.dispose();
    dateOfBirthController.dispose();
    placeOfBirthController.dispose();
    documentNumberController.dispose();
    sexoController.dispose();
    fatherNameController.dispose();
    motherNameController.dispose();
    domicilioController.dispose();
    fechaDeExpedicionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    DateTime initialDate = DateTime.now();
    if (controller.text.isNotEmpty) {
      try {
        initialDate = DateTime.parse(controller.text.split('/').reversed.join('-'));
      } catch (e) {
        // Ignore parsing errors, default to current date
      }
    }
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != initialDate) {
      setState(() {
        controller.text =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
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
                      "Extracted Information",
                      style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16.sp),
                    AppTextFormField(
                      enabled: true,
                      label: 'Name',
                      textEditingController: nameController,
                    ),
                    SizedBox(height: 16.sp),
                    GestureDetector(
                      onTap: () => _selectDate(context, dateOfBirthController),
                      child: AbsorbPointer(
                        child: AppTextFormField(
                          enabled: true,
                          label: 'Date of Birth',
                          textEditingController: dateOfBirthController,
                        ),
                      ),
                    ),
                    SizedBox(height: 16.sp),
                    DropdownButtonFormField<String>(
                      value: selectedPlaceOfBirth,
                      items: validPlacesOfBirth
                          .map((place) => DropdownMenuItem(
                                value: place,
                                child: Text(place),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedPlaceOfBirth = value;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Place of Birth',
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0.r),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.sp),
                    AppTextFormField(
                      enabled: true,
                      label: 'Document Number',
                      textEditingController: documentNumberController,
                    ),
                    SizedBox(height: 16.sp),
                    DropdownButtonFormField<String>(
                      value: selectedSexo, // Preselect based on extraction result
                      items: ['M', 'F']
                          .map((sexo) => DropdownMenuItem(
                                value: sexo,
                                child: Text(sexo),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedSexo = value;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Sexo',
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0.r),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.sp),
                    AppTextFormField(
                      enabled: true,
                      label: 'Father\'s Name',
                      textEditingController: fatherNameController,
                    ),
                    SizedBox(height: 16.sp),
                    AppTextFormField(
                      enabled: true,
                      label: 'Mother\'s Name',
                      textEditingController: motherNameController,
                    ),
                    SizedBox(height: 16.sp),
                    AppTextFormField(
                      enabled: true,
                      label: 'Domicilio',
                      textEditingController: domicilioController,
                    ),
                    SizedBox(height: 16.sp),
                    GestureDetector(
                      onTap: () => _selectDate(context, fechaDeExpedicionController),
                      child: AbsorbPointer(
                        child: AppTextFormField(
                          enabled: true,
                          label: 'Expiry Date',
                          textEditingController: fechaDeExpedicionController,
                        ),
                      ),
                    ),
                    SizedBox(height: 16.sp),
                    Row(
                      children: [
                        Checkbox.adaptive(
                          value: isConfirmed,
                          onChanged: (value) {
                            setState(() {
                              isConfirmed = value ?? false;
                            });
                          },
                        ),
                        const Flexible(
                          child: Text(
                            "I confirm that the information is correct and verified.",
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
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
                                  if (rectoImage != null && versoImage != null) {
                                    isCaptureDone = true;
                                  }
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
                                  if (rectoImage != null && versoImage != null) {
                                    isCaptureDone = true;
                                  }
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
      final namePattern = RegExp(r'NOMBRE\s+(.+?)\n');
      final birthDatePattern = RegExp(r'FECHA DE NACIMIENTO\s+(\d{2}/\d{2}/\d{4})');
      final placeOfBirthPattern = RegExp(r'\bW\.\s+([^\n]+)'); // Matches 'W.' followed by text
      final documentNumberPattern = RegExp(r'(\d{8,})'); // Look for 8+ digit numbers

      final nameMatch = namePattern.firstMatch(text);
      if (nameMatch != null) nameController.text = nameMatch.group(1)!.trim();

      final birthDateMatch = birthDatePattern.firstMatch(text);
      if (birthDateMatch != null) dateOfBirthController.text = birthDateMatch.group(1)!.trim();

      final placeOfBirthMatch = placeOfBirthPattern.firstMatch(text);
      if (placeOfBirthMatch != null) {
        final extractedPlaceOfBirth = placeOfBirthMatch.group(0)!.trim().toUpperCase();

        // Match with predefined list
        final match = validPlacesOfBirth.firstWhere(
          (place) => extractedPlaceOfBirth.contains(place),
          orElse: () => '',
        );

        setState(() {
          selectedPlaceOfBirth = match.isNotEmpty ? match : null;
        });
      } else {
        selectedPlaceOfBirth = null; // No match found
      }

      final documentNumberMatch = documentNumberPattern.firstMatch(text);
      if (documentNumberMatch != null) {
        documentNumberController.text = documentNumberMatch.group(1)!.trim();
      }

      debugPrint(
          "Front Data Extracted: Name=${nameController.text}, DOB=${dateOfBirthController.text}, Place=${placeOfBirthController.text}, DocNumber=${documentNumberController.text}");
    } else if (documentType == DocumentsType.rasdBackIdCard) {
      final sexoPattern = RegExp(r'SEXO\s+([MF])');
      final fatherNamePattern = RegExp(r'NOMBRE DEL PADRE\s+(.+?)\n');
      final motherNamePattern = RegExp(r'NOMBRE DE LA MADRE\s+(.+?)\n');
      final domicilioPattern = RegExp(r'DOMICILIO\s+(.+?)\n');
      final datePattern = RegExp(r'(\d{2}/\d{2}/\d{4})'); // Match any date in DD/MM/YYYY format

      // Extract Sexo
      final sexoMatch = sexoPattern.firstMatch(text);
      if (sexoMatch != null) {
        final extractedSexo = sexoMatch.group(1)!.trim();
        if (extractedSexo == 'M' || extractedSexo == 'F') {
          setState(() {
            selectedSexo = extractedSexo;
          });
        } else {
          selectedSexo = null; // Default value if extraction is invalid
        }
      } else {
        selectedSexo = null; // Default value if extraction fails
      }

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

      debugPrint(
          "Back Data Extracted: Sexo=${sexoController.text}, Father=${fatherNameController.text}, Mother=${motherNameController.text}, Domicilio=${domicilioController.text}, ExpiryDate=${fechaDeExpedicionController.text}");
    }
  }

  bool _isDocumentRecognized(String text, DocumentsType docType) {
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
}
