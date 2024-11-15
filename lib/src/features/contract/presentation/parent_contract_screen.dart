import 'dart:io';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:diacritic/diacritic.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:insta_image_viewer/insta_image_viewer.dart';
import 'package:mobilis_smart_pos/src/core/commom/widgets/custom_appbar_with_deny_contract.dart';
import 'package:mobilis_smart_pos/src/core/commom/widgets/custom_floating_action_button.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/app_localization_helper.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/media_query_values.dart';
import 'package:mobilis_smart_pos/src/services/screenshot_service.dart';

import '../../../config/routing/app_routes.dart';
import '../../../core/commom/widgets/app_text_form_field.dart';
import '../../../core/commom/widgets/commune_drop_down.dart';
import '../../../core/commom/widgets/wilaya_drop_down.dart';
import '../../../core/utils/enums/documents_type.dart';
import '../../../core/utils/enums/input_type.dart';
import '../../../core/utils/helpers/civils_informations_converter_helper.dart';
import '../../../core/utils/helpers/json_loader_helper.dart';
import '../../../core/utils/helpers/toast_helper.dart';
import '../../profile/presentation/widget/upload_image_field.dart';
import '../domain/entities/commune_entity.dart';
import '../domain/entities/contract_request_params_entitiy.dart';
import '../domain/entities/wilaya_entity.dart';

class ParentContractScreen extends StatefulWidget {
  const ParentContractScreen({
    super.key,
    required this.minorContract,
    this.minorRecto,
    this.minorVerso,
    required this.minorIsPassport,
    required this.parentIsPassport,
    required this.parentExtractedNFCData,
  });

  final ContractRequestParamsEntitiy minorContract;
  final File? minorRecto;
  final File? minorVerso;
  final bool minorIsPassport;
  final bool parentIsPassport;
  final Map<String, dynamic> parentExtractedNFCData;

  @override
  State<ParentContractScreen> createState() => _ParentContractScreenState();
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

class _ParentContractScreenState extends State<ParentContractScreen> {
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
      _filteredCommunes = _communes
          .where((commune) => commune.stateCode == wilayaCode)
          .toList();
    });
  }

  File? rectoImage;
  File? versoImage;
  File? justficatif;
  bool isCaptureDone = false;
  TextRecognizer recognizer = TextRecognizer();

  @override
  void initState() {
    super.initState();
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

  bool _isDocumentRecognizedText(String text, DocumentsType docType) {
    if (docType == DocumentsType.frontIdCard) {
      final pattern9Digits = RegExp(r'\b\d{9}\b');
      final has9Digits = pattern9Digits.hasMatch(text);
      return has9Digits;
    } else if (docType == DocumentsType.backIdCard) {
      final patternIdDza = RegExp(r'IDDZA');
      final patternName = RegExp(r'Nom');
      final patternSymol = RegExp(r'<<<');

      final hasIdDza = patternIdDza.hasMatch(text);
      final hasName = patternName.hasMatch(text);
      final hasSymbols = patternSymol.hasMatch(text);
      return (hasIdDza && hasName && hasSymbols);
    } else if (docType == DocumentsType.passport) {
      final patternP = RegExp(r'P<');
      final pattern9Digits = RegExp(r'\b\d{9}\b');

      final hasP = patternP.hasMatch(text);
      final has9Digits = pattern9Digits.hasMatch(text);
      return hasP && has9Digits;
    } else {
      return true;
    }
  }

  Future<bool> checkDocument(
      {required TextRecognizer recognizer,
      required File file,
      required DocumentsType docType}) async {
    final document = InputImage.fromFile(file);
    final recognizedText = await recognizer.processImage(document);
    final isDocumentRecognized =
        _isDocumentRecognizedText(recognizedText.text, docType);
    return isDocumentRecognized;
  }

  Future<void> captureDocument({
    required TextRecognizer recognizer,
    required DocumentsType docType,
    required BuildContext context,
  }) async {
    final imagesPath = await CunningDocumentScanner.getPictures(
        noOfPages: 1, isGalleryImportAllowed: false);
    if (imagesPath != null && imagesPath.isNotEmpty) {
      File file = File(imagesPath[0]);
      final validated = await checkDocument(
          recognizer: recognizer, file: file, docType: docType);
      if (validated) {
        if (docType == DocumentsType.passport) {
          setState(() {
            rectoImage = file;
          });
        } else if (docType == DocumentsType.frontIdCard) {
          setState(() {
            rectoImage = file;
          });
        } else if (docType == DocumentsType.backIdCard) {
          setState(() {
            versoImage = file;
          });
          if (!widget.parentIsPassport &&
              rectoImage != null &&
              versoImage != null &&
              justficatif != null) {
            setState(() {
              isCaptureDone = true;
            });
          }
        } else if (docType == DocumentsType.justificatif) {
          setState(() {
            justficatif = file;
          });
          if (widget.parentIsPassport &&
              rectoImage != null &&
              justficatif != null) {
            setState(() {
              isCaptureDone = true;
            });
          } else if (!widget.parentIsPassport &&
              rectoImage != null &&
              versoImage != null &&
              justficatif != null) {
            setState(() {
              isCaptureDone = true;
            });
          }
        }
      } else {
        AppToasts.showWarningToast(
            message: "incorrect_image".tr(context), context: context);
        return;
      }
    } else {
      return;
    }
  }

  _onFABPressed() async {
    bool isValidated = _formKey.currentState!.validate();

    if (!isValidated) {
      AppToasts.showErrorToast(
        message: "all_fields".tr(context),
        onAutoCompleteCompleted: (p0) {},
        context: context,
      );
      return;
    }

    if (_selectedWilaya == null) {
      AppToasts.showErrorToast(
        message: "required_wilaya".tr(context),
        onAutoCompleteCompleted: (p0) {},
        context: context,
      );
      return;
    }

    if (_selectedCommune == null) {
      AppToasts.showErrorToast(
        message: "required_commune".tr(context),
        onAutoCompleteCompleted: (p0) {},
        context: context,
      );
      return;
    }

    if (RegExp(r'[\u0600-\u06FF]').hasMatch(addressEditingController.text)) {
      AppToasts.showErrorToast(
          message: "address_french_instruction".tr(context), context: context);
      return;
    }

    // Trim text fields and assign to variables
    String nin = ninController.text.trim();
    String docNumber = docNumberController.text.trim();
    String issuingCountry = issuingCountryController.text.trim();
    String issuingPlace = issuingPlaceControllerController.text.trim();
    String docType = docTypeController.text.trim();
    String bloodType = bloodTypeController.text.trim();

    String firstName = firstNameEditingController.text.trim();
    firstName = firstName.replaceAll(RegExp(r'-\s*'), ' ');
    String lastName = lastNameEditingController.text.trim();
    lastName = lastName.replaceAll(RegExp(r'-\s*'), ' ');
    String birthPlace = birthPlaceEditingController.text.trim();
    String nationality = nationalityEditingController.text.trim();
    String normalizedAddress =
        removeDiacritics(addressEditingController.text.trim());
    String cleanedAddress =
        normalizedAddress.replaceAll(RegExp(r'[^a-zA-Z0-9 ]'), '');
    String address = cleanedAddress;

    ContractRequestParamsEntitiy contract = widget.minorContract.copyWith(
      parentFirstName: firstName,
      parentLastName: lastName,
      parentGender: CivilsInformationsConverterHelper.getToSubmitGenderValue(
        gender: widget.parentExtractedNFCData['gender'],
      ),
      parentBirthDate:
          CivilsInformationsConverterHelper.convertToIso8601WithTiret(
        widget.parentExtractedNFCData['date_of_birth'],
      ),
      parentBirthPlace: birthPlace,
      parentNationality: nationality,
      parentWilayaId: int.parse(_selectedWilaya!),
      parentCommune: _selectedCommune,
      parentStreet: address.toUpperCase(),
      parentNin: nin,
      parentDocumentType:
          CivilsInformationsConverterHelper.getToSubmitDocumentTypeValue(
        docType: widget.parentExtractedNFCData['document_type'],
      ),
      parentDocumentNumber: docNumber,
      parentIssuingCountry: issuingCountry,
      parentIssuingPlace: issuingPlace,
      parentIssueDate:
          CivilsInformationsConverterHelper.convertToIso8601WithTiret(
        widget.parentExtractedNFCData['date_of_delivery'],
      ),
    );

    Navigator.of(context).pushNamed(Routes.barCode, arguments: {
      'contract': contract,
      'recto': widget.minorRecto,
      'verso': widget.minorVerso,
      'isPassport': widget.minorIsPassport,
      'parentRecto': rectoImage,
      'parentVerso': versoImage,
      'justificatif': justficatif,
      'parentIsPassport': widget.parentIsPassport
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      floatingActionButton: isCaptureDone
          ? CustomFAB(
              label: "continuer".tr(context),
              icon: CupertinoIcons.right_chevron,
              onPressed: _onFABPressed,
            )
          : null,
      appBar: CustomAppbarWithDenyContract(
        title: "step02_parent_contract".tr(context),
        showProgressIndicator: true,
        currentStep: 6,
        allSteps: 8,
      ),
      body: SingleChildScrollView(
        child: Container(
          width: context.width,
          padding: EdgeInsets.fromLTRB(24.sp, 32.sp, 24.sp, 96.sp),
          child: Form(
              key: _formKey,
              child: Column(
                children: [
                  CivilsDocument(parentData: widget.parentExtractedNFCData),
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
                        disabledValue:
                            widget.parentExtractedNFCData['first_name'],
                        textEditingController: firstNameEditingController,
                        label: "firstNameLabel".tr(context),
                        // validationType: InputType.FIRST_NAME,
                      ),
                      SizedBox(height: 16.sp),
                      AppTextFormField(
                        enabled: false,
                        disabledValue:
                            widget.parentExtractedNFCData['last_name'],
                        textEditingController: lastNameEditingController,
                        label: "lastNameLabel".tr(context),
                      ),
                      SizedBox(height: 16.sp),

                      AppTextFormField(
                        enabled: false,
                        disabledValue:
                            CivilsInformationsConverterHelper.getFormatedGender(
                                gender: widget.parentExtractedNFCData['gender'],
                                context: context),
                        textEditingController: genderEditingController,
                        label: "genderLabel".tr(context),
                      ),
                      SizedBox(height: 16.sp),
                      AppTextFormField(
                        enabled: false,
                        disabledValue: CivilsInformationsConverterHelper
                            .formatToDisplayDate(
                                date: widget
                                    .parentExtractedNFCData['date_of_birth'],
                                context: context),
                        textEditingController: birthDateEditingController,
                        label: "birthDateLabel".tr(context),
                      ),
                      SizedBox(height: 16.sp),
                      AppTextFormField(
                        enabled: false,
                        disabledValue:
                            widget.parentExtractedNFCData['place_of_birth'],
                        textEditingController: birthPlaceEditingController,
                        label: "birthPlaceLabel".tr(context),
                      ),
                      SizedBox(height: 16.sp),
                      AppTextFormField(
                        enabled: false,
                        disabledValue:
                            widget.parentExtractedNFCData['Nationality'],
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
                              label: widget.parentIsPassport
                                  ? "passport".tr(context)
                                  : "recto".tr(context),
                              onTap: () async {
                                return await captureDocument(
                                  recognizer: recognizer,
                                  docType: widget.parentIsPassport
                                      ? DocumentsType.passport
                                      : DocumentsType.frontIdCard,
                                  context: context,
                                );
                              }),
                      if (!widget.parentIsPassport && rectoImage != null)
                        Column(
                          children: [
                            SizedBox(height: 16.sp),
                            versoImage != null
                                ? InstaImageViewer(
                                    child: Image.file(versoImage!))
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
                      SizedBox(height: 12.sp),
                      justficatif != null
                          ? InstaImageViewer(child: Image.file(justficatif!))
                          : UploadImageField(
                              icon: FontAwesomeIcons.camera,
                              label: "justification".tr(context),
                              onTap: () async {
                                return await captureDocument(
                                  recognizer: recognizer,
                                  docType: DocumentsType.justificatif,
                                  context: context,
                                );
                              }),
                      SizedBox(height: 48.sp),
                    ],
                  ),
                ],
              )),
        ),
      ),
    ));
  }
}

class CivilsDocument extends StatelessWidget {
  const CivilsDocument({
    super.key,
    required this.parentData,
  });

  final Map parentData;

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
            docType: parentData['document_type'],
            context: context,
          ),
          textEditingController: docTypeController,
          label: "documentTypeLabel".tr(context),
        ),
        SizedBox(height: 16.sp),
        AppTextFormField(
          enabled: false,
          disabledValue: parentData['personal_number'],
          textEditingController: ninController,
          label: "ninLabel".tr(context),
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: 16.sp),
        AppTextFormField(
          enabled: false,
          disabledValue: parentData['document_number'],
          textEditingController: docNumberController,
          label: "documentNumberLabel".tr(context),
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: 16.sp),
        AppTextFormField(
          enabled: false,
          disabledValue: parentData['issuing_state'],
          textEditingController: issuingCountryController,
          label: "issuingCountryLabel".tr(context),
        ),
        SizedBox(height: 16.sp),
        AppTextFormField(
          enabled: false,
          disabledValue: parentData['issuing_authority'],
          label: "issuingPlaceLabel".tr(context),
          textEditingController: issuingPlaceControllerController,
        ),
        SizedBox(height: 16.sp),
        AppTextFormField(
          enabled: false,
          disabledValue: CivilsInformationsConverterHelper.formatToDisplayDate(
              date: parentData['date_of_delivery'], context: context),
          textEditingController: issuingDateController,
          label: "issuingDateLabel".tr(context),
        ),
        SizedBox(height: 16.sp),
        SizedBox(height: 32.sp),
      ],
    );
  }
}
