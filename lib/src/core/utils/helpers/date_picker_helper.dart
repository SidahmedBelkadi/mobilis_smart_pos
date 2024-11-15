import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DatePickerHelper {
  DatePickerHelper._();

  static Future<String?> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      return DateFormat('dd-MM-yyyy').format(picked);
    }
    return null;
  }
}
