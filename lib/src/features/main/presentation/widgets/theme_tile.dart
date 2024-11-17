import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/utils/enums/themes_enum.dart';
import '../../../../core/utils/helpers/app_localization_helper.dart';
import '../../../../core/utils/ressources/app_colors.dart';

class ThemeTile extends StatelessWidget {
  final AppThemes selectedTheme;
  final ValueChanged<String> onThemeChanged;

  const ThemeTile({
    super.key,
    required this.selectedTheme,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 10.sp),
      child: ListTile(
        leading: Icon(
          FontAwesomeIcons.moon,
          color: AppColors.secondary,
          size: 16.sp,
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("dark_mode".tr(context), style: Theme.of(context).textTheme.bodySmall),
            Switch(
              value: selectedTheme.name == AppThemes.darkTheme.name,
              onChanged: (value) {
                onThemeChanged(
                    value == true ? AppThemes.darkTheme.name : AppThemes.lightTheme.name);
              },
            ),
          ],
        ),
      ),
    );
  }
}
