import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/daira_entity.dart';

import '../../utils/helpers/app_localization_helper.dart';
import '../../utils/helpers/media_query_values.dart';
import '../../utils/ressources/app_colors.dart';

class DairaDropDown extends StatelessWidget {
  const DairaDropDown({
    super.key,
    required this.onChanged,
    required this.items,
    this.selectedValue,
  });

  final void Function(String?)? onChanged;
  final List<Daira> items;
  final String? selectedValue;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedValue,
      hint: Text(
        "selectDairaLabel".tr(context),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.secondaryLight,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        label: Text("DairaLabel".tr(context)),
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.categorybackgroundColorGrey),
          borderRadius: BorderRadius.circular(12.sp),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.categorybackgroundColorGrey),
          borderRadius: BorderRadius.circular(12.sp),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.categorybackgroundColorGrey),
          borderRadius: BorderRadius.circular(12.sp),
        ),
      ),
      iconSize: 24,
      items: items.map((Daira daira) {
        return DropdownMenuItem<String>(
          value: daira.code,
          child: Text(
            context.isArabicLocale ? daira.arName : daira.name,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
