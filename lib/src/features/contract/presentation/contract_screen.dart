import 'dart:io';

import 'package:diacritic/diacritic.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:insta_image_viewer/insta_image_viewer.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/session_timeout.dart';
import 'package:mobilis_smart_pos/src/services/native_camera_scanner.dart';
import '../../../core/commom/widgets/custom_appbar_with_deny_contract.dart';
import '../../../core/commom/widgets/custom_floating_action_button.dart';
import '../../../core/utils/enums/documents_type.dart';
import '../domain/entities/wilaya_entity.dart';
import '../../profile/presentation/widget/upload_image_field.dart';
import '../../../services/screenshot_service.dart';

import '../../../config/routing/app_routes.dart';
import '../../../core/commom/widgets/app_text_form_field.dart';
import '../../../core/commom/widgets/commune_drop_down.dart';
import '../../../core/commom/widgets/wilaya_drop_down.dart';
import '../../../core/utils/enums/input_type.dart';
import '../../../core/utils/helpers/app_localization_helper.dart';
import '../../../core/utils/helpers/civils_informations_converter_helper.dart';
import '../../../core/utils/helpers/json_loader_helper.dart';
import '../../../core/utils/helpers/media_query_values.dart';
import '../../../core/utils/helpers/toast_helper.dart';
import '../../../dependency_injection/injection_container.dart' as di;
import '../../sign_in/data/data_sources/smart_pos_local_storage.dart';
import '../../sign_out/presentation/cubit/sign_out_cubit.dart';
import '../domain/entities/commune_entity.dart';
import '../domain/entities/contract_request_params_entitiy.dart';

class ContractScreen extends StatefulWidget {
  const ContractScreen({
    super.key,
    required this.metaData,
    required this.isMinor,
    this.isPresumed,
  });

  final Map metaData;
  final bool isMinor;
  final bool? isPresumed;

  @override
  State<ContractScreen> createState() => _ContractScreenState();
}

late TextEditingController ninController;
late TextEditingController docNumberController;
late TextEditingController issuingCountryController;
late TextEditingController issuingPlaceControllerController;
late TextEditingController issuingDateController;
late TextEditingController docTypeController;
late TextEditingController bloodTypeController;

late TextEditingController firstNameEditingController;
late TextEditingController lastNameEditingController;
late TextEditingController genderEditingController;
late TextEditingController birthDateEditingController;
late TextEditingController birthPlaceEditingController;
late TextEditingController nationalityEditingController;
late TextEditingController addressEditingController;
late TextEditingController emailEditingController;
GlobalKey<FormState> _formKey = GlobalKey();

class _ContractScreenState extends State<ContractScreen> {
  List<Wilaya> _wilayas = [];
  List<Commune> _communes = [];
  List<Commune> _filteredCommunes = [];
  String? _selectedWilaya;
  String? _selectedCommune;

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

  File? rectoImage;
  File? versoImage;
  bool isCaptureDone = false;

  @override
  void initState() {
    super.initState();

    final String isoBirthDate = CivilsInformationsConverterHelper.convertToIso8601(
      widget.metaData['date_of_birth'],
    );

    if (isoBirthDate.isNotEmpty) {
      try {
        final DateTime birthDate = DateTime.parse(isoBirthDate);
        final DateTime today = DateTime.now();

        // Calculate the age
        int age = today.year - birthDate.year;

        // Adjust for the birthday not yet reached this year
        if (today.month < birthDate.month ||
            (today.month == birthDate.month && today.day < birthDate.day)) {
          age--;
        }

        if (age < 19) {
          if (!widget.isMinor) {
            AppToasts.showInfoToast(
                message: "THIS_MINOR_IS_PRESUMING_TO_BE_ADULT".tr(context), context: context);
            Navigator.of(context)
                .pushNamedAndRemoveUntil(Routes.home, (route) => false, arguments: {'index': 1});
            return;
          }
        }
      } catch (e) {
        debugPrint("Error parsing birth date: $e");
      }
    } else {
      debugPrint("============== Birth date is not provided or invalid.");
    }

    ScreenshotService.preventScreenshotOn();

    _loadData();

    ninController = TextEditingController();
    docNumberController = TextEditingController();
    issuingCountryController = TextEditingController();
    issuingPlaceControllerController = TextEditingController();
    issuingDateController = TextEditingController();
    docTypeController = TextEditingController();
    bloodTypeController = TextEditingController();

    firstNameEditingController = TextEditingController();
    lastNameEditingController = TextEditingController();
    genderEditingController = TextEditingController();
    birthDateEditingController = TextEditingController();
    birthPlaceEditingController = TextEditingController();
    nationalityEditingController = TextEditingController();
    addressEditingController = TextEditingController();
    emailEditingController = TextEditingController();
  }

  @override
  void dispose() {
    super.dispose();
    ScreenshotService.preventScreenshotOff();

    ninController.dispose();
    docNumberController.dispose();
    issuingCountryController.dispose();
    issuingPlaceControllerController.dispose();
    issuingDateController.dispose();
    docTypeController.dispose();
    bloodTypeController.dispose();

    firstNameEditingController.dispose();
    lastNameEditingController.dispose();
    genderEditingController.dispose();
    birthDateEditingController.dispose();
    birthPlaceEditingController.dispose();
    nationalityEditingController.dispose();
    addressEditingController.dispose();
  }

  late ContractRequestParamsEntitiy contract;

  _onFABPressed() async {
    bool isValidated = _formKey.currentState!.validate();

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

    if (RegExp(r'[\u0600-\u06FF]').hasMatch(addressEditingController.text)) {
      AppToasts.showErrorToast(message: "address_french_instruction".tr(context), context: context);
      return;
    }

    // Trim text fields and assign to variables
    String nin = ninController.text.trim();
    String docNumber = docNumberController.text.trim();
    String issuingCountry = issuingCountryController.text.trim();
    String issuingPlace = issuingPlaceControllerController.text.trim();
    String bloodType = bloodTypeController.text.trim();

    String firstName = firstNameEditingController.text.trim();
    firstName = firstName.replaceAll(RegExp(r'-\s*'), ' ');
    String lastName = lastNameEditingController.text.trim();
    lastName = lastName.replaceAll(RegExp(r'-\s*'), ' ');
    if (lastName.isEmpty || lastName == "") {
      lastName = "SNP";
    }
    String birthPlace = birthPlaceEditingController.text.trim();
    String nationality = nationalityEditingController.text.trim();
    String normalizedAddress = removeDiacritics(addressEditingController.text.trim());
    String cleanedAddress = normalizedAddress.replaceAll(RegExp(r'[^a-zA-Z0-9 ]'), '');
    String address = cleanedAddress;

    late int pdvId;
    late int employeeId;
    final getSavedLoginCredentials =
        di.serviceLocator<SmartPosLocalStorage>().getSavedLoginCredentials();
    if (getSavedLoginCredentials != null) {
      pdvId = getSavedLoginCredentials.userId!;
      employeeId = getSavedLoginCredentials.employeeId!;
    } else {
      context.read<SignOutCubit>().signOut(context);
      return;
    }

    contract = ContractRequestParamsEntitiy(
      firstName: firstName,
      lastName: lastName,
      gender: CivilsInformationsConverterHelper.getToSubmitGenderValue(
        gender: widget.metaData['gender'],
      ),
      birthDate: CivilsInformationsConverterHelper.convertToIso8601(
        widget.metaData['date_of_birth'],
      ),
      presumedBirthDate: widget.isPresumed != null
          ? CivilsInformationsConverterHelper.convertToIso8601(
              widget.metaData['date_of_birth'],
            )
          : null,
      birthPlace: birthPlace,
      nationality: nationality,
      wilayaId: int.parse(_selectedWilaya!),
      commune: _selectedCommune!,
      street: address.toUpperCase(),
      folderUrl: null,
      nin: nin,
      documentType: CivilsInformationsConverterHelper.getToSubmitDocumentTypeValue(
        docType: widget.metaData['document_type'],
      ),
      documentNumber: docNumber,
      issuingCountry: issuingCountry,
      issuingPlace: issuingPlace,
      issueDate: CivilsInformationsConverterHelper.convertToIso8601WithTiret(
          widget.metaData['date_of_delivery']),
      bloodGroup: bloodType,
      pdvId: pdvId,
      employeeId: employeeId,
      email: emailEditingController.text.trim(),
    );

    widget.isMinor
        ? Navigator.of(context).pushNamed(Routes.parentPreparation, arguments: {
            'contract': contract,
            'recto': rectoImage,
            'verso': versoImage,
            'isPassport': widget.metaData['document_type'] == 'passport' ? true : false
          })
        : Navigator.of(context).pushNamed(Routes.barCode, arguments: {
            'contract': contract,
            'recto': rectoImage,
            'verso': versoImage,
            'isPassport': widget.metaData['document_type'] == 'passport' ? true : false
          });
  }

  bool _isDocumentRecognizedText(String text, DocumentsType docType) {
    if (docType == DocumentsType.frontIdCard) {
      final pattern9Digits = RegExp(r'\b\d{9}\b');
      final has9Digits = pattern9Digits.hasMatch(text);
      final match = pattern9Digits.firstMatch(text);
      if (match != null) {
        final extractedNumber = match.group(0);
        return has9Digits && extractedNumber == widget.metaData['document_number'];
      }
      return false;
    } else if (docType == DocumentsType.backIdCard) {
      final patternIdDza = RegExp(r'IDDZA');
      final hasIdDza = patternIdDza.hasMatch(text);
      return hasIdDza;
    } else {
      final patternP = RegExp(r'P<');

      final hasP = patternP.hasMatch(text);
      final pattern18Digits = RegExp(r'\b\d{18}\b');
      final match = pattern18Digits.firstMatch(text);
      if (match != null) {
        final extractedNumber = match.group(0);
        return hasP && extractedNumber == widget.metaData['personal_number'];
      }
      return false;
    }
  }

  Future<bool> checkDocument({
    required TextRecognizer recognizer,
    required File file,
    required DocumentsType docType,
  }) async {
    final document = InputImage.fromFile(file);
    final recognizedText = await recognizer.processImage(document);
    final isDocumentRecognized = _isDocumentRecognizedText(recognizedText.text, docType);
    return isDocumentRecognized;
  }

  Future<void> captureDocument({
    required TextRecognizer recognizer,
    required DocumentsType docType,
    required BuildContext context,
  }) async {
    final imagesPath = await NativeDocumentScanner.getPictures();

    if (imagesPath.isNotEmpty) {
      File file = File(imagesPath[0]);
      final validated = await checkDocument(recognizer: recognizer, file: file, docType: docType);
      if (validated) {
        if (docType == DocumentsType.passport) {
          setState(() {
            rectoImage = file;
            isCaptureDone = true;
          });
        } else if (docType == DocumentsType.frontIdCard) {
          setState(() {
            rectoImage = file;
          });
        } else if (docType == DocumentsType.backIdCard) {
          setState(() {
            versoImage = file;
          });
          if (rectoImage != null) {
            setState(() {
              isCaptureDone = true;
            });
          }
        }
      } else {
        // Display toast message specific to document type
        String message;
        switch (docType) {
          case DocumentsType.passport:
            message = "incorrect_passport_image".tr(context);
            break;
          case DocumentsType.frontIdCard:
            message = "incorrect_front_id_card_image".tr(context);
            break;
          case DocumentsType.backIdCard:
            message = "incorrect_back_id_card_image".tr(context);
            break;
          default:
            message = "incorrect_image".tr(context);
            break;
        }
        AppToasts.showWarningToast(message: message, context: context);
        return;
      }
    } else {
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isPassport = widget.metaData['document_type'] == 'passport';
    final TextRecognizer recognizer = TextRecognizer();

    return SessionTimeout(
      child: Scaffold(
        appBar: CustomAppbarWithDenyContract(
          title: "contractTitle".tr(context),
          showProgressIndicator: true,
          currentStep: 3,
          allSteps: widget.isMinor ? 8 : 5,
        ),
        floatingActionButton: isCaptureDone
            ? CustomFAB(
                label: "continuer".tr(context),
                icon: CupertinoIcons.right_chevron,
                onPressed: _onFABPressed,
              )
            : null,
        body: SingleChildScrollView(
          child: Container(
            width: context.width,
            padding: EdgeInsets.fromLTRB(24.sp, 32.sp, 24.sp, 96.sp),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // =============== Document Civil
                  CivilsDocument(widget: widget),

                  // =============== Info Client

                  Row(
                    children: [
                      const Icon(Icons.arrow_right_sharp),
                      Text(
                        "infos_client".tr(context),
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(decoration: TextDecoration.underline),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  Column(
                    children: [
                      AppTextFormField(
                        enabled: false,
                        disabledValue: widget.metaData['first_name'],
                        textEditingController: firstNameEditingController,
                        label: "firstNameLabel".tr(context),
                        validationType: InputType.NONE,
                      ),
                      SizedBox(height: 16.sp),
                      AppTextFormField(
                        enabled: false,
                        disabledValue: widget.metaData['last_name'],
                        textEditingController: lastNameEditingController,
                        label: "lastNameLabel".tr(context),
                        validationType: InputType.NONE,
                      ),
                      SizedBox(height: 16.sp),

                      AppTextFormField(
                        enabled: false,
                        disabledValue: CivilsInformationsConverterHelper.getFormatedGender(
                            gender: widget.metaData['gender'], context: context),
                        textEditingController: genderEditingController,
                        label: "genderLabel".tr(context),
                      ),
                      SizedBox(height: 16.sp),
                      AppTextFormField(
                        enabled: false,
                        disabledValue: CivilsInformationsConverterHelper.formatToDisplayDate(
                            date: widget.metaData['date_of_birth'], context: context),
                        textEditingController: birthDateEditingController,
                        label: "birthDateLabel".tr(context),
                      ),
                      SizedBox(height: 16.sp),
                      AppTextFormField(
                        enabled: false,
                        disabledValue: widget.metaData['place_of_birth'],
                        textEditingController: birthPlaceEditingController,
                        label: "birthPlaceLabel".tr(context),
                      ),
                      SizedBox(height: 16.sp),
                      AppTextFormField(
                        enabled: false,
                        disabledValue: widget.metaData['Nationality'],
                        textEditingController: nationalityEditingController,
                        label: "nationality".tr(context),
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
                      SizedBox(height: 16.sp),
                      AppTextFormField(
                        isRequired: false,
                        label: "email".tr(context),
                        validationType: InputType.EMAIL,
                        textEditingController: emailEditingController,
                      ),
                      SizedBox(height: 16.sp),
                      rectoImage != null
                          ? InstaImageViewer(child: Image.file(rectoImage!))
                          : UploadImageField(
                              icon: FontAwesomeIcons.camera,
                              label: isPassport ? "passport".tr(context) : "recto".tr(context),
                              onTap: () async {
                                return await captureDocument(
                                  recognizer: recognizer,
                                  docType: isPassport
                                      ? DocumentsType.passport
                                      : DocumentsType.frontIdCard,
                                  context: context,
                                );
                              }),
                      if (!isPassport && rectoImage != null)
                        Column(
                          children: [
                            SizedBox(height: 16.sp),
                            versoImage != null
                                ? InstaImageViewer(child: Image.file(versoImage!))
                                : UploadImageField(
                                    icon: FontAwesomeIcons.camera,
                                    label: "verso".tr(context),
                                    onTap: () async {
                                      return await captureDocument(
                                          recognizer: recognizer,
                                          docType: DocumentsType.backIdCard,
                                          context: context);
                                    }),
                          ],
                        ),
                      SizedBox(height: 48.sp),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CivilsDocument extends StatelessWidget {
  const CivilsDocument({
    super.key,
    required this.widget,
  });

  final ContractScreen widget;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.arrow_right_sharp),
            Text(
              "infos_civil".tr(context),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(decoration: TextDecoration.underline),
            ),
          ],
        ),
        SizedBox(height: 16.sp),
        AppTextFormField(
          enabled: false,
          disabledValue: CivilsInformationsConverterHelper.getDocumentTypeName(
            docType: widget.metaData['document_type'],
            context: context,
          ),
          textEditingController: docTypeController,
          label: "documentTypeLabel".tr(context),
        ),
        SizedBox(height: 16.sp),
        AppTextFormField(
          enabled: false,
          disabledValue: widget.metaData['personal_number'],
          textEditingController: ninController,
          label: "ninLabel".tr(context),
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: 16.sp),
        AppTextFormField(
          enabled: false,
          disabledValue: widget.metaData['document_number'],
          textEditingController: docNumberController,
          label: "documentNumberLabel".tr(context),
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: 16.sp),
        AppTextFormField(
          enabled: false,
          disabledValue: widget.metaData['issuing_state'],
          textEditingController: issuingCountryController,
          label: "issuingCountryLabel".tr(context),
        ),
        SizedBox(height: 16.sp),
        AppTextFormField(
          enabled: false,
          disabledValue: widget.metaData['issuing_authority'],
          label: "issuingPlaceLabel".tr(context),
          textEditingController: issuingPlaceControllerController,
        ),
        SizedBox(height: 16.sp),
        AppTextFormField(
          enabled: false,
          disabledValue: CivilsInformationsConverterHelper.formatToDisplayDate(
              date: widget.metaData['date_of_delivery'], context: context),
          textEditingController: issuingDateController,
          label: "issuingDateLabel".tr(context),
        ),
        SizedBox(height: 16.sp),
        SizedBox(height: 32.sp),
      ],
    );
  }
}
