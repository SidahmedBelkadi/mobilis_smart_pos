import 'package:flutter/material.dart';

import '../utils/enums/input_type.dart';
import '../utils/helpers/app_localization_helper.dart';
import 'validation_patterns.dart';

class Validator {
  Validator._();

  static String? validate({
    required BuildContext context,
    required String value,
    required InputType type,
    bool isRequired = true,
  }) {
    if (isRequired && value.isEmpty) {
      return "requiredError".tr(context);
    }

    if (value.isNotEmpty) {
      switch (type) {
        case InputType.NONE:
        case InputType.FIRST_NAME:
          if (!RegExp(ValidationPatterns.namePattern).hasMatch(value)) {
            return "firstNameError".tr(context);
          }
          break;
        case InputType.LAST_NAME:
          if (!RegExp(ValidationPatterns.namePattern).hasMatch(value)) {
            return "lastNameError".tr(context);
          }
          break;
        case InputType.PHONE:
          if (!RegExp(ValidationPatterns.phonePattern).hasMatch(value)) {
            return "phoneError".tr(context);
          }
          break;
        case InputType.PASSWORD:
          if (!RegExp(ValidationPatterns.passwordPattern).hasMatch(value)) {
            return "passwordError".tr(context);
          }
          break;
        case InputType.STRONG_PASSWORD:
          if (!RegExp(ValidationPatterns.strongPasswordPattern).hasMatch(value)) {
            return "strongPasswordError".tr(context);
          }
          break;
        case InputType.EMAIL:
          if (!RegExp(ValidationPatterns.emailPattern).hasMatch(value)) {
            return "emailError".tr(context);
          }
          break;
        case InputType.ADDRESS:
          if (!RegExp(ValidationPatterns.addressPattern).hasMatch(value)) {
            return "addressError".tr(context);
          }
          break;
        case InputType.YEARS_OF_EXPERIENCE:
          if (!RegExp(ValidationPatterns.yearsOfExperiencePattern).hasMatch(value)) {
            return "yearsOfExperienceError".tr(context);
          }
          break;
        case InputType.NIN:
          if (!RegExp(ValidationPatterns.ninPattern).hasMatch(value)) {
            return "ninError".tr(context);
          }
          break;
        case InputType.DOCUMENT_NUMBER:
          if (!RegExp(ValidationPatterns.documentNumberPattern).hasMatch(value)) {
            return "documentNumberError".tr(context);
          }
          break;
        case InputType.RASD_DOCUMENT_NUMBER:
          if (!RegExp(ValidationPatterns.rasdDocumentNumberPattern).hasMatch(value)) {
            return "rasdDocumentNumberError".tr(context);
          }
          break;
        case InputType.ISSUING_COUNTRY:
          if (!RegExp(ValidationPatterns.issuingCountryPattern).hasMatch(value)) {
            return "issuingCountryError".tr(context);
          }
          break;
        case InputType.ISSUING_PLACE:
          if (!RegExp(ValidationPatterns.issuingPlacePattern).hasMatch(value)) {
            return "issuingPlaceError".tr(context);
          }
          break;
        case InputType.ISSUING_DATE:
          if (!RegExp(ValidationPatterns.datePattern).hasMatch(value)) {
            return "issuingDateError".tr(context);
          }
          break;
        case InputType.DOCUMENT_TYPE:
          if (!RegExp(ValidationPatterns.documentTypePattern).hasMatch(value)) {
            return "documentTypeError".tr(context);
          }
          break;
        case InputType.BLOOD_GROUP:
          if (!RegExp(ValidationPatterns.bloodGroupPattern).hasMatch(value)) {
            return "bloodGroupError".tr(context);
          }
          break;
        case InputType.GENDER:
          if (!RegExp(ValidationPatterns.genderPattern).hasMatch(value)) {
            return "genderError".tr(context);
          }
          break;
        case InputType.BIRTH_DATE:
          if (!RegExp(ValidationPatterns.datePattern).hasMatch(value)) {
            return "birthDateError".tr(context);
          }
          break;
        case InputType.COMMERCIAL_REGISTER:
          if (!RegExp(ValidationPatterns.commercialRegisterPattern).hasMatch(value)) {
            return "commercialRegisterError".tr(context);
          }
          break;
        case InputType.CODE_OF_COMMERCIAL_REGISTER:
          if (!RegExp(ValidationPatterns.codeOfCommercialRegisterPattern).hasMatch(value)) {
            return "codeOfCommercialRegisterError".tr(context);
          }
          break;
        case InputType.TAX_IDENTIFICATION_NUMBER:
          if (!RegExp(ValidationPatterns.taxIdentificationNumberPattern).hasMatch(value)) {
            return "taxIdentificationNumberError".tr(context);
          }
          break;
        case InputType.COMPANY_NAME:
          if (!RegExp(ValidationPatterns.companyNamePattern).hasMatch(value)) {
            return "companyNameError".tr(context);
          }
          break;
        case InputType.WILAYA:
          if (!RegExp(ValidationPatterns.wilayaPattern).hasMatch(value)) {
            return "wilayaError".tr(context);
          }
          break;
        case InputType.DAIRA:
          if (!RegExp(ValidationPatterns.dairaPattern).hasMatch(value)) {
            return "dairaError".tr(context);
          }
          break;
        default:
          return null;
      }
    }
    return null;
  }
}
