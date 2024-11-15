import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/utils/ressources/app_colors.dart';

InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
  contentPadding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 20.h),
  labelStyle: TextStyle(
    fontSize: 14.sp,
    color: AppColors.secondaryText,
    fontWeight: FontWeight.w500,
  ),
  floatingLabelBehavior: FloatingLabelBehavior.auto,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12.0.r),
    borderSide: const BorderSide(color: AppColors.inputBorder),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12.0.r),
    borderSide: const BorderSide(color: AppColors.primary, width: 2),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12.0.r),
    borderSide: const BorderSide(color: Colors.red, width: 2),
  ),
  errorStyle: TextStyle(fontSize: 10.sp, color: Colors.red, overflow: TextOverflow.visible),
  floatingLabelStyle: WidgetStateTextStyle.resolveWith((Set<WidgetState> states) {
    if (states.contains(WidgetState.error)) {
      return TextStyle(color: Colors.red, fontSize: 12.sp);
    }
    return TextStyle(
      fontSize: 12.sp,
      color: AppColors.secondaryText,
      fontWeight: FontWeight.w500,
    );
  }),
);
