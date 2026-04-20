import 'package:flutter/material.dart';
import 'app_localization_helper.dart';

class LocalizationUtils {
  static String getLocalizedDuration(BuildContext context, int days) {
    final languageCode = AppLocalizations.of(context)?.locale?.languageCode ?? 'en';

    if (languageCode == 'ar') {
      if (days == 1) return "day_1".tr(context);
      if (days == 2) return "day_2".tr(context);
      if (days >= 3 && days <= 10) return "day_3_10".tr(context).replaceFirst('{n}', days.toString());
      return "day_11_plus".tr(context).replaceFirst('{n}', days.toString());
    } else if (languageCode == 'fr') {
      if (days <= 1) return "day_singular".tr(context).replaceFirst('{n}', days.toString());
      return "day_plural".tr(context).replaceFirst('{n}', days.toString());
    } else {
      // English
      if (days == 1) return "day_singular".tr(context);
      return "day_plural".tr(context).replaceFirst('{n}', days.toString());
    }
  }
}
