import 'package:shared_preferences/shared_preferences.dart';

import '../ressources/app_keys.dart';

abstract class LanguageCacheHelper {
  static Future<void> cacheLanguageCode(String languageCode) async {
    final sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setString(AppKeys.locale, languageCode);
  }

  static Future<String> getCachedLanguageCode() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    final cachedLanguageCode = sharedPreferences.getString(AppKeys.locale);

    if (cachedLanguageCode != null) {
      return cachedLanguageCode;
    } else {
      return 'ar';
    }
  }
}
