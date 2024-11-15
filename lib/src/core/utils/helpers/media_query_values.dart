import 'package:flutter/material.dart';

extension MediaQueryValues on BuildContext {
  double get width => MediaQuery.of(this).size.width;
  double get height => MediaQuery.of(this).size.height;
  double get topPadding => MediaQuery.of(this).viewPadding.top;
  double get bottom => MediaQuery.of(this).viewInsets.bottom;

  // Method to check if the current locale is Arabic
  bool get isArabicLocale {
    return Localizations.localeOf(this).languageCode == 'ar';
  }
  bool get isFrenchLocale {
    return Localizations.localeOf(this).languageCode == 'fr';
  }

  bool get isDarkMode {
    return Theme.of(this).brightness == Brightness.dark;
  }
}
