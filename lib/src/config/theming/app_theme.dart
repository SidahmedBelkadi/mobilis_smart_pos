import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobilis_smart_pos/src/config/theming/widgets/dark/app_bar.dart';
import 'package:mobilis_smart_pos/src/config/theming/widgets/dark/elevated_button.dart';
import 'package:mobilis_smart_pos/src/config/theming/widgets/dark/form_field.dart';
import 'package:mobilis_smart_pos/src/config/theming/widgets/dark/text.dart';

import '../../core/utils/ressources/app_colors.dart';
import 'widgets/app_bar.dart';
import 'widgets/elevated_button.dart';
import 'widgets/form_field.dart';
import 'widgets/text.dart';

ThemeData smartDealerTheme(Locale locale) {
  return ThemeData(
      // ------- General Theming ---------
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.green,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      fontFamily: locale.languageCode == 'ar'
          ? GoogleFonts.notoSansArabic().fontFamily
          : GoogleFonts.dmSans().fontFamily,
      // ------- General Theming ---------

      /// Smart Dealer AppBar Theme
      appBarTheme: appBarTheme,

      /// Smart Dealer Text Theme
      textTheme: textTheme,

      /// Smart Dealer Text Theme
      inputDecorationTheme: inputDecorationTheme,

      /// Smart Dealer Elevated Button Theme
      elevatedButtonTheme: elevatedButtonThemeData,

      /// Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
      bottomSheetTheme:
          const BottomSheetThemeData(backgroundColor: Colors.white),
      popupMenuTheme: const PopupMenuThemeData(color: Colors.white));
}

ThemeData smartDealerThemeDark(Locale locale) {
  return ThemeData(

      // ------- General Theming ---------
      scaffoldBackgroundColor: AppColors.darkGrey,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.green,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      fontFamily: locale.languageCode == 'ar'
          ? GoogleFonts.notoSansArabic().fontFamily
          : GoogleFonts.dmSans().fontFamily,
      // ------- General Theming ---------

      /// Smart Dealer AppBar Theme
      appBarTheme: appBarThemeDark,

      /// Smart Dealer Text Theme
      textTheme: textThemeDark,

      /// Smart Dealer Text Theme
      inputDecorationTheme: inputDecorationThemeDark,

      /// Smart Dealer Elevated Button Theme
      elevatedButtonTheme: elevatedButtonThemeDataDark,

      /// Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
      bottomSheetTheme:
          const BottomSheetThemeData(backgroundColor: Colors.black),
      popupMenuTheme: const PopupMenuThemeData(color: Colors.black));
}
