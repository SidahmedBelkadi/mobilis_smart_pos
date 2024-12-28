import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'media_query_values.dart';

class CivilsInformationsConverterHelper {
  CivilsInformationsConverterHelper._();

  static String activationSerialNumberPrefix = "892130";

  // Gender formatting based on locale
  static String getFormatedGender({
    required String gender,
    required BuildContext context,
  }) {
    if (gender == "MALE") {
      return context.isArabicLocale ? "ذكر" : "Male";
    } else {
      return context.isArabicLocale ? "أنثى" : "Female";
    }
  }

  // Convert gender to submit-friendly value
  static String getToSubmitGenderValue({required String gender}) {
    return gender == "MALE" ? "Male" : "Female";
  }

  // Convert document type to submit-friendly value
  static String getToSubmitDocumentTypeValue({required String docType}) {
    return docType == "passport" ? "Passport" : "ID Card";
  }

  // Get document type name based on locale
  static String getDocumentTypeName({
    required String docType,
    required BuildContext context,
  }) {
    if (context.isArabicLocale) {
      return docType == "passport" ? "جواز سفر" : "بطاقة هوية";
    } else {
      return docType == "passport" ? "Passport" : "Carte d'identité";
    }
  }

  // Format date for display with locale handling
  static String formatToDisplayDate({
    required String date,
    required BuildContext context,
  }) {
    try {
      DateTime parsedDate = parseDate(date);
      if (context.isArabicLocale) {
        return DateFormat('yyyy-MM-dd').format(parsedDate);
      }
      return DateFormat('dd-MM-yyyy').format(parsedDate);
    } catch (e) {
      return 'Invalid Date';
    }
  }

  // Convert date from 'yyyy/MM/dd' to 'dd-MM-yyyy'
  static String convertDateFormat({required String date}) {
    try {
      DateTime parsedDate = DateFormat('yyyy/MM/dd').parse(date);
      return DateFormat('dd-MM-yyyy').format(parsedDate);
    } catch (e) {
      return 'Invalid Date';
    }
  }

  // Convert date from 'dd/MM/yyyy' to ISO 8601 format
  static String convertToIso8601(String dateStr) {
    debugPrint("=================== ISO date : $dateStr");
    try {
      String year = dateStr.substring(0, 4);
      String month = dateStr.substring(4, 6);
      String day = dateStr.substring(6, 8);

      if (month == '00' || day == '00') {
        // Replace invalid month or day with "01"
        month = month == '00' ? '01' : month;
        day = day == '00' ? '01' : day;
      }
      DateTime parsedDate = DateFormat('yyyy-MM-dd').parseStrict('$year-$month-$day');
      debugPrint("===================HEY : ${parsedDate.toIso8601String()}");
      return parsedDate.toIso8601String();
    } catch (e) {
      return 'Invalid Date';
    }
  }

  // Convert date from 'yyyy-MM-dd' to ISO 8601 format
  static String convertToIso8601WithTiret(String dateStr) {
    try {
      DateTime parsedDate = DateFormat('yyyy-MM-dd').parse(dateStr);
      return parsedDate.toIso8601String();
    } catch (e) {
      debugPrint("============ ERROR : $e");
      return 'Invalid Date';
    }
  }

  // Helper method to parse dates in various formats
  static DateTime parseDate(String date) {
    try {
      if (date.contains('-')) {
        return DateFormat('yyyy-MM-dd').parse(date);
      } else if (date.contains('/')) {
        return DateFormat('yyyy/MM/dd').parse(date);
      } else if (date.length == 8) {
        // Handle special cases where month or day is "00"
        String year = date.substring(0, 4);
        String month = date.substring(4, 6);
        String day = date.substring(6, 8);

        if (month == '00' || day == '00') {
          // Replace invalid month or day with "01"
          month = month == '00' ? '01' : month;
          day = day == '00' ? '01' : day;

          // Construct a valid date
          String fixedDate = '$year-$month-$day';
          DateTime parsedDate = DateFormat('yyyy-MM-dd').parse(fixedDate);
          return parsedDate;
        }

        String fixedDate = '$year-$month-$day';
        DateTime parsedDate = DateFormat('yyyy-MM-dd').parse(fixedDate);
        return parsedDate;
      } else {
        throw const FormatException('Unknown date format');
      }
    } catch (e) {
      throw FormatException('============ Error parsing date: $e');
    }
  }

  // Convert date from 'yyyyMMdd' to 'yyyy-MM-dd'
  static String convertToStandardDateFormat(String date) {
    try {
      DateTime parsedDate = DateFormat('yyyyMMdd').parse(date);
      return DateFormat('yyyy-MM-dd').format(parsedDate);
    } catch (e) {
      print('Error converting date: $e');
      return 'Invalid Date';
    }
  }
}
