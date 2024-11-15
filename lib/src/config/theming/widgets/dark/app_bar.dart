import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/ressources/app_colors.dart';



AppBarTheme appBarThemeDark = const AppBarTheme(
  systemOverlayStyle: SystemUiOverlayStyle(statusBarColor: AppColors.primary, statusBarIconBrightness: Brightness.dark, statusBarBrightness: Brightness.dark),
  elevation: 0,
  scrolledUnderElevation: 0,
  backgroundColor: Colors.black,
  foregroundColor: AppColors.primary,
  centerTitle: false,
);
