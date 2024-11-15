import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../features/contract/domain/entities/commune_entity.dart';
import '../../utils/helpers/app_localization_helper.dart';
import '../../utils/helpers/media_query_values.dart';
import '../../utils/ressources/app_colors.dart';

class CommuneDropDown extends StatelessWidget {
  const CommuneDropDown({
    super.key,
    required this.onChanged,
    required this.items,
    this.selectedValue,
  });

  final void Function(String?)? onChanged;
  final List<Commune> items;
  final String? selectedValue;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedValue,
      hint: Text(
        "selectCommuneLabel".tr(context),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: context.isDarkMode ? AppColors.primary : AppColors.secondaryLight,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        label: Text("CommuneLabel".tr(context)),
        border: OutlineInputBorder(
          borderSide:  BorderSide(color: context.isDarkMode ? AppColors.primary : AppColors.categorybackgroundColorGrey),
          borderRadius: BorderRadius.circular(12.sp),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide:  BorderSide(color:context.isDarkMode ? AppColors.primary : AppColors.categorybackgroundColorGrey),
          borderRadius: BorderRadius.circular(12.sp),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide:  BorderSide(color: context.isDarkMode ? AppColors.primary : AppColors.categorybackgroundColorGrey),
          borderRadius: BorderRadius.circular(12.sp),
        ),
      ),
      iconSize: 24,
      items: items.map((Commune commune) {
        return DropdownMenuItem<String>(
          value: commune.name.toUpperCase(),
          child: Text(
            context.isArabicLocale ? commune.arName : commune.name.toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
