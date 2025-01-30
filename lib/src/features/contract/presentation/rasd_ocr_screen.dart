import 'dart:io';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:insta_image_viewer/insta_image_viewer.dart';
import 'package:intl/intl.dart';
import 'package:mobilis_smart_pos/src/config/routing/app_routes.dart';
import 'package:mobilis_smart_pos/src/core/commom/widgets/app_text_form_field.dart';
import 'package:mobilis_smart_pos/src/core/commom/widgets/commune_drop_down.dart';
import 'package:mobilis_smart_pos/src/core/commom/widgets/custom_app_bar.dart';
import 'package:mobilis_smart_pos/src/core/commom/widgets/custom_floating_action_button.dart';
import 'package:mobilis_smart_pos/src/core/commom/widgets/wilaya_drop_down.dart';
import 'package:mobilis_smart_pos/src/core/utils/enums/documents_type.dart';
import 'package:mobilis_smart_pos/src/core/utils/enums/input_type.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/app_localization_helper.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/civils_informations_converter_helper.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/json_loader_helper.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/media_query_values.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/toast_helper.dart';
import 'package:mobilis_smart_pos/src/core/utils/ressources/app_colors.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/commune_entity.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/rasd_request_params_entity.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/wilaya_entity.dart';
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
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController dateOfBirthController = TextEditingController();
  final TextEditingController placeOfBirthController = TextEditingController();
  final TextEditingController documentNumberController = TextEditingController();
  final TextEditingController sexoController = TextEditingController();
  final TextEditingController fatherNameController = TextEditingController();
  final TextEditingController motherNameController = TextEditingController();
  final TextEditingController domicilioController = TextEditingController();
  final TextEditingController fechaDeExpedicionController = TextEditingController();
  final TextEditingController addressEditingController = TextEditingController();
  final TextEditingController emailEditingController = TextEditingController();

  // Form Key
  final GlobalKey<FormState> _rasdFormKey = GlobalKey();

  // Dropdown for Sexo
  String? selectedSexo;

// Wilaya & Commune
  List<Wilaya> _wilayas = [];
  List<Commune> _communes = [];
  List<Commune> _filteredCommunes = [];
  String? _selectedWilaya;
  String? _selectedCommune;

  @override
  void initState() {
    _loadData();
    _textRecognizer = TextRecognizer();
    super.initState();
  }

  @override
  void dispose() {
    _textRecognizer.close();
    firstNameController.dispose();
    lastNameController.dispose();
    dateOfBirthController.dispose();
    placeOfBirthController.dispose();
    documentNumberController.dispose();
    sexoController.dispose();
    fatherNameController.dispose();
    motherNameController.dispose();
    domicilioController.dispose();
    fechaDeExpedicionController.dispose();
    addressEditingController.dispose();
    emailEditingController.dispose();
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
      final dateStr =
          "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      debugPrint("=============== date Str : $dateStr");
      setState(() {
        controller.text = dateStr;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: isCaptureDone
          ? CustomFAB(
              label: "continuer".tr(context),
              icon: CupertinoIcons.right_chevron,
              onPressed: () {
                final isValidated = _rasdFormKey.currentState!.validate();
                if (!isValidated) {
                  AppToasts.showWarningToast(
                    message: "all_fields".tr(context),
                    context: context,
                  );
                  return;
                }

                if (_selectedWilaya == null) {
                  AppToasts.showWarningToast(
                    message: "required_wilaya".tr(context),
                    context: context,
                  );
                  return;
                }

                if (_selectedCommune == null) {
                  AppToasts.showWarningToast(
                    message: "required_commune".tr(context),
                    context: context,
                  );
                  return;
                }

                if (selectedSexo == null) {
                  AppToasts.showWarningToast(
                    message: "select_sexe".tr(context),
                    context: context,
                  );
                  return;
                }
                if (!isConfirmed) {
                  AppToasts.showWarningToast(
                    message: "rasd_checkbox_error".tr(context),
                    context: context,
                  );
                  return;
                }

                if (dateOfBirthController.text.isNotEmpty) {
                  try {
                    DateTime birthDate = DateFormat("dd/MM/yyyy").parse(dateOfBirthController.text);
                    DateTime now = DateTime.now();
                    int age = now.year - birthDate.year;
                    if (now.month < birthDate.month ||
                        (now.month == birthDate.month && now.day < birthDate.day)) {
                      age--;
                    }

                    if (age < 19) {
                      AppToasts.showWarningToast(
                        message: "rasd_minor_message".tr(context),
                        context: context,
                      );
                      // return;
                    }
                  } catch (e) {
                    return;
                  }
                }

                RasdEditRequestParamsEntity params = RasdEditRequestParamsEntity(
                  firstName: firstNameController.text,
                  birthLastName: lastNameController.text,
                  gender: CivilsInformationsConverterHelper.getToSubmitGenderRasdValue(
                      gender: selectedSexo!),
                  birthDate: CivilsInformationsConverterHelper.convertToIso8601Rasd(
                      dateOfBirthController.text),
                  birthPlace: placeOfBirthController.text,
                  wilayaId: _selectedWilaya!,
                  street: addressEditingController.text,
                  commune: _selectedCommune!,
                  email: emailEditingController.text,
                  documentType: "ID Card",
                  documentNumber: documentNumberController.text,
                  issueDate: CivilsInformationsConverterHelper.convertToIso8601Rasd(
                      fechaDeExpedicionController.text),
                  address: addressEditingController.text,
                );

                // debugPrint(prettyPrintJson(jsonEncode(params.toJson())));

                Navigator.of(context).pushNamed(Routes.rasdBarCodeScanner, arguments: {
                  'rasdParams': params,
                  'recto': rectoImage,
                  'verso': versoImage,
                });
                return;
              },
            )
          : null,
      appBar: CustomAppBar(title: "contractTitle".tr(context)),
      body: Container(
        padding: EdgeInsets.all(24.sp),
        height: context.height,
        width: context.width,
        child: isCaptureDone
            ? SingleChildScrollView(
                child: Column(
                  children: [
                    OCRInstruction(
                      child: Text(
                        "rasd_ocr_instruction".tr(context),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Form(
                      key: _rasdFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppTextFormField(
                            enabled: true,
                            label: 'firstNameLabel'.tr(context),
                            textEditingController: firstNameController,
                            validationType: InputType.FIRST_NAME,
                          ),
                          SizedBox(height: 16.sp),
                          AppTextFormField(
                            enabled: true,
                            label: 'lastNameLabel'.tr(context),
                            textEditingController: lastNameController,
                            validationType: InputType.LAST_NAME,
                          ),
                          SizedBox(height: 16.sp),
                          GestureDetector(
                            onTap: () => _selectDate(context, dateOfBirthController),
                            child: AbsorbPointer(
                              child: AppTextFormField(
                                enabled: true,
                                label: "birthDateLabel".tr(context),
                                textEditingController: dateOfBirthController,
                              ),
                            ),
                          ),
                          SizedBox(height: 16.sp),
                          AppTextFormField(
                            enabled: true,
                            label: "birthPlaceLabel".tr(context),
                            textEditingController: placeOfBirthController,
                            validationType: InputType.ADDRESS,
                          ),
                          SizedBox(height: 16.sp),
                          AppTextFormField(
                            enabled: true,
                            label: "documentNumberLabel".tr(context),
                            textEditingController: documentNumberController,
                            validationType: InputType.RASD_DOCUMENT_NUMBER,
                          ),
                          SizedBox(height: 16.sp),
                          DropdownButtonFormField<String>(
                            value: selectedSexo,
                            items: ['M', 'F']
                                .map(
                                  (sexo) => DropdownMenuItem(
                                    value: sexo,
                                    child: Text(sexo.tr(context)),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedSexo = value;
                              });
                            },
                            decoration: InputDecoration(
                              labelText: "genderLabel".tr(context),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0.r),
                                borderSide: const BorderSide(color: AppColors.primary, width: 2),
                              ),
                            ),
                          ),
                          SizedBox(height: 16.sp),
                          AppTextFormField(
                            enabled: true,
                            label: 'domicilio'.tr(context),
                            textEditingController: domicilioController,
                            validationType: InputType.ADDRESS,
                          ),
                          SizedBox(height: 16.sp),
                          GestureDetector(
                            onTap: () => _selectDate(context, fechaDeExpedicionController),
                            child: AbsorbPointer(
                              child: AppTextFormField(
                                enabled: true,
                                label: 'expirationDateLabel'.tr(context),
                                textEditingController: fechaDeExpedicionController,
                              ),
                            ),
                          ),
                          SizedBox(height: 16.sp),
                          AppTextFormField(
                            isRequired: false,
                            label: "email".tr(context),
                            validationType: InputType.EMAIL,
                            textEditingController: emailEditingController,
                          ),
                          SizedBox(height: 16.sp),
                          // === Wilaya & daira & commune drop downs
                          WilayaDropDown(
                            items: _wilayas,
                            onChanged: (value) {
                              _filterCommunes(value);
                            },
                          ),
                          SizedBox(height: 16.sp),
                          CommuneDropDown(
                            items: _filteredCommunes,
                            selectedValue: _selectedCommune,
                            onChanged: (value) {
                              setState(() {
                                _selectedCommune = value;
                              });
                            },
                          ),
                          SizedBox(height: 16.sp),
                          AppTextFormField(
                            isLatinOnly: true,
                            label: "streetLabel".tr(context),
                            validationType: InputType.ADDRESS,
                            textEditingController: addressEditingController,
                          ),
                          SizedBox(height: 32.sp),

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
                              : const SizedBox(),
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
                              : const SizedBox(),
                          SizedBox(height: 32.sp),
                          OCRInstruction(
                            child: CheckboxListTile(
                              title: Text("rasd_checkbox".tr(context),
                                  style: Theme.of(context).textTheme.bodySmall),
                              value: isConfirmed,
                              onChanged: (value) {
                                setState(() {
                                  isConfirmed = value ?? false;
                                });
                              },
                            ),
                          ),
                          SizedBox(height: 64.sp),
                        ],
                      ),
                    ),
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

  File convertToGrayscale(File imageFile) {
    final image = img.decodeImage(imageFile.readAsBytesSync())!;
    final grayscaleImage = img.grayscale(image);
    final grayscaleFile = File('${imageFile.path}_grayscale.png');
    grayscaleFile.writeAsBytesSync(img.encodePng(grayscaleImage));
    return grayscaleFile;
  }

  File reduceNoise(File imageFile, {int radius = 1}) {
    // Decode the image file
    final image = img.decodeImage(imageFile.readAsBytesSync())!;

    // Apply Gaussian blur to reduce noise
    final noiseReducedImage = img.gaussianBlur(image, radius: radius);

    // Save the noise-reduced image to a new file
    final noiseReducedFile = File('${imageFile.path}_noise_reduced.png');
    noiseReducedFile.writeAsBytesSync(img.encodePng(noiseReducedImage));

    return noiseReducedFile;
  }

  File binarizeImage(File imageFile, {int threshold = 128}) {
    final image = img.decodeImage(imageFile.readAsBytesSync())!;
    final binaryImage = img.copyResize(image, width: image.width, height: image.height);

    for (var y = 0; y < binaryImage.height; y++) {
      for (var x = 0; x < binaryImage.width; x++) {
        final pixel = binaryImage.getPixel(x, y);
        final luminance = img.getLuminance(pixel);

        // Set pixel to black or white based on the threshold
        final newColor = luminance > threshold ? 255 : 0;

        // Use setPixelRgba with 6 arguments (x, y, r, g, b, a)
        binaryImage.setPixelRgba(x, y, newColor, newColor, newColor, 255); // 255 = fully opaque
      }
    }

    final binaryFile = File('${imageFile.path}_binary.png');
    binaryFile.writeAsBytesSync(img.encodePng(binaryImage));
    return binaryFile;
  }

  Future<void> _loadData() async {
    final wilayas = await JsonLoaderHelper.loadWilayas();
    final communes = await JsonLoaderHelper.loadCommunes();
    setState(() {
      _wilayas = wilayas;
      _communes = communes;
    });
  }

  void _filterCommunes(String? wilayaCode) {
    setState(() {
      _selectedWilaya = wilayaCode;
      _selectedCommune = null;
      _filteredCommunes = _communes.where((commune) => commune.stateCode == wilayaCode).toList();
    });
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
      File preProcessFile = file;
      // Preprocess the image (convert to grayscale)
      preProcessFile = convertToGrayscale(file);
      preProcessFile = reduceNoise(file);

      // Use the preprocessed image for OCR
      final inputImage = InputImage.fromFile(preProcessFile);
      final recognizedText = await recognizer.processImage(inputImage);

      debugPrint("===== Recognized Text : \n ${recognizedText.text}");

      // Validate the document
      final isValid = _isDocumentRecognized(recognizedText.text, docType);
      if (isValid) {
        // Extract data if valid
        extractAndStoreData(recognizedText.text, docType);

        return file;
      } else {
        // Show error message if not valid
        String message;
        switch (docType) {
          case DocumentsType.rasdFrontIdCard:
            // ignore: use_build_context_synchronously
            message = "incorrect_front_id_card_image".tr(context);
            break;
          case DocumentsType.rasdBackIdCard:
            // ignore: use_build_context_synchronously
            message = "incorrect_back_id_card_image".tr(context);
            break;
          default:
            message = "incorrect_image".tr(context);
            break;
        }
        // ignore: use_build_context_synchronously
        AppToasts.showWarningToast(message: message, context: context);
      }
    }
    return null;
  }

  // Helper function to check if extracted text is a common label
  bool _isCommonLabel(String text) {
    final labels = [
      "FECHA",
      "NACIMIENTO",
      "LUGAR",
      "DOCUMENTO",
      "SEXO",
      "PADRE",
      "MADRE",
      "DOMICILIO"
    ];
    return labels.any((label) => text.contains(label));
  }

  void extractAndStoreData(String text, DocumentsType documentType) {
    if (documentType == DocumentsType.rasdFrontIdCard) {
      final birthDatePattern = RegExp(r'\b(\d{2}/\d{2}/\d{4})\b');

      final placeOfBirthPattern = RegExp(r'\bW\.\s+([^\n]+)'); // Matches 'W.' followed by text
      final lugarNacimientoPattern =
          RegExp(r'LUGAR DE NACIMIENTO\s+([^\n]+)', caseSensitive: false);

      final documentNumberPattern = RegExp(r'(\d{8,})'); // Look for 8+ digit numbers
      final nombreVariations = ["NOMBRE", "NONMEE", "NONBRE", "NOME", "NOMEE", "NOBRE"];
      final namePattern =
          RegExp(r'\b([A-Z][a-z]+(?:-[A-Z][a-z]+)?(?:\s+[A-Z][a-z]+(?:-[A-Z][a-z]+)?)*)\b');

      String? extractedName;

      debugPrint("=========  Starting name extraction process...");

      // Step 1: Look for "NOMBRE" (or OCR variations) and extract name after it
      for (final variation in nombreVariations) {
        final index = text.indexOf(variation);
        if (index != -1) {
          debugPrint("=========  Found potential name label: $variation at index $index");
          final afterNombre = text.substring(index + variation.length).trim();
          final nameMatch = namePattern.firstMatch(afterNombre);
          if (nameMatch != null) {
            extractedName = nameMatch.group(1);
            debugPrint("=========  Extracted name after 'NOMBRE': $extractedName");
            break;
          }
        }
      }

      // Step 2: If no match, try finding the name before "FECHA DE NACIMIENTO"
      if (extractedName == null) {
        final birthDateIndex = text.indexOf("FECHA DE NACIMIENTO");
        if (birthDateIndex != -1) {
          debugPrint("=========  'FECHA DE NACIMIENTO' found at index $birthDateIndex");
          final beforeBirthDate = text.substring(0, birthDateIndex);
          final nameMatch = namePattern.firstMatch(beforeBirthDate);
          if (nameMatch != null) {
            extractedName = nameMatch.group(1);
            debugPrint("=========  Extracted name before 'FECHA DE NACIMIENTO': $extractedName");
          }
        }
      }

      // Step 3: If still no match, take the first valid uppercase name
      if (extractedName == null) {
        debugPrint("========= Trying fallback method to find any valid name...");
        final nameMatches = namePattern.allMatches(text);
        for (final match in nameMatches) {
          final candidate = match.group(1)!;
          debugPrint("========= Found potential name: $candidate");
          if (!_isCommonLabel(candidate)) {
            extractedName = candidate;
            debugPrint("=========  Selected valid name: $extractedName");
            break;
          }
        }
      }

      // Store extracted name in text controllers
      if (extractedName != null) {
        final nameParts = extractedName.split(' ');
        firstNameController.text = nameParts.first;
        lastNameController.text = nameParts.skip(1).join(' ');
        debugPrint("=========  Final extracted first name: ${firstNameController.text}");
        debugPrint("=========  Final extracted last name: ${lastNameController.text}");
      } else {
        debugPrint("=========  No valid name extracted.");
      }

      final birthDateMatch = birthDatePattern.firstMatch(text);
      if (birthDateMatch != null) dateOfBirthController.text = birthDateMatch.group(1)!.trim();

      String? placeOfBirth;

      // Try to match 'W.' first
      final wMatch = placeOfBirthPattern.firstMatch(text);
      if (wMatch != null) {
        placeOfBirth = wMatch.group(0); // Get the matched value
      } else {
        // Step 2: Fallback to 'Lugar de Nacimiento'
        final lugarMatch = lugarNacimientoPattern.firstMatch(text);
        if (lugarMatch != null) {
          placeOfBirth = lugarMatch.group(1)?.trim(); // Extract value after the keyword
        }
      }

      if (placeOfBirth != null) {
        placeOfBirthController.text = placeOfBirth;
      }

      final documentNumberMatch = documentNumberPattern.firstMatch(text);
      if (documentNumberMatch != null) {
        documentNumberController.text = documentNumberMatch.group(1)!.trim();
      }
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
    }
  }

  bool _isDocumentRecognized(String text, DocumentsType docType) {
    final normalizedText = text.toLowerCase().replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ');

    if (docType == DocumentsType.rasdFrontIdCard) {
      final patterns = [
        RegExp(r'republica', caseSensitive: false),
        RegExp(r'árabe', caseSensitive: false),
        RegExp(r'saharaui', caseSensitive: false),
        RegExp(r'democrática', caseSensitive: false),
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

class OCRInstruction extends StatelessWidget {
  const OCRInstruction({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: context.width,
          padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 16.sp),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(.1),
            borderRadius: BorderRadius.all(
              Radius.circular(12.sp),
            ),
          ),
          child: child,
        ),
      ],
    );
  }
}
