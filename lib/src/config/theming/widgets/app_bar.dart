import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/ressources/app_colors.dart';

AppBarTheme appBarTheme = const AppBarTheme(
  systemOverlayStyle: SystemUiOverlayStyle(statusBarColor: AppColors.primary),
  elevation: 0,
  scrolledUnderElevation: 0,
  backgroundColor: Colors.white,
  foregroundColor: AppColors.primary,
  centerTitle: false,
);
