import '../ressources/app_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LaunchHelper {
  final SharedPreferences sharedPreferences;
  LaunchHelper({required this.sharedPreferences});

  bool isFirstTime() {
    final bool? result = sharedPreferences.getBool(AppKeys.firstLaunch);
    return result ?? true;
  }

  Future<void> firstTime() async {
    await sharedPreferences.setBool(AppKeys.firstLaunch, false);
  }
}
