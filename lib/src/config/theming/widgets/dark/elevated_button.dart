import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/utils/ressources/app_colors.dart';



ElevatedButtonThemeData elevatedButtonThemeDataDark = ElevatedButtonThemeData(
  style: ElevatedButton.styleFrom(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
    foregroundColor: Colors.black,
    backgroundColor: AppColors.primary,
  ),
);
