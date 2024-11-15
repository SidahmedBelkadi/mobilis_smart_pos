import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_switch/flutter_switch.dart'; // Import the flutter_switch package
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobilis_smart_pos/src/core/utils/enums/themes_enum.dart';
import 'package:mobilis_smart_pos/src/core/utils/ressources/app_colors.dart';

class ThemeSwitcher extends StatelessWidget {
  final AppThemes selectedTheme;
  final ValueChanged<String> onThemeChanged;

  const ThemeSwitcher({
    super.key,
    required this.selectedTheme,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 10.sp),
      child: FlutterSwitch(
          duration: const Duration(seconds: 0),
          width: 60.sp,
          height: 30.sp,
          toggleSize: 25.sp,
          value: selectedTheme.name == AppThemes.darkTheme.name,
          borderRadius: 30.sp,
          activeIcon: Icon(
            FontAwesomeIcons.solidMoon,
            color: AppColors.secondary,
            size: 16.sp,
          ),
          inactiveIcon: Icon(
            FontAwesomeIcons.solidSun,
            color: Colors.yellow,
            size: 16.sp,
          ),
          activeColor: Colors.grey[800]!,
          inactiveColor: AppColors.secondary,
          onToggle: (value) {
            onThemeChanged(value == true
                ? AppThemes.darkTheme.name
                : AppThemes.lightTheme.name);
          }),
    );
  }
}
