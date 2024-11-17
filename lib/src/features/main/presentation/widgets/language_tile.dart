import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/utils/helpers/media_query_values.dart';

import '../../../../core/utils/helpers/app_localization_helper.dart';
import '../../../../core/utils/ressources/app_colors.dart';

class LanguageTile extends StatelessWidget {
  final String selectedLanguage;
  final ValueChanged<String> onLanguageChanged;

  const LanguageTile({
    super.key,
    required this.selectedLanguage,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 10.sp),
      child: ListTile(
        leading: FaIcon(
          FontAwesomeIcons.language,
          color: AppColors.secondary,
          size: 16.sp,
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Lang".tr(context), style: Theme.of(context).textTheme.bodySmall),
            DropdownButton<String>(
              dropdownColor: context.isDarkMode ? Colors.black : Colors.white,
              value: selectedLanguage,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.green),
              underline: Container(),
              // Remove the underline
              onChanged: (String? newValue) {
                if (newValue != null) {
                  onLanguageChanged(newValue);
                }
              },
              items: <String>['ar', 'fr', 'en'].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value.tr(context),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
