import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/wilaya_entity.dart';

import '../../utils/helpers/app_localization_helper.dart';
import '../../utils/helpers/media_query_values.dart';
import '../../utils/ressources/app_colors.dart';

class WilayaDropDown extends StatelessWidget {
  const WilayaDropDown({
    super.key,
    required this.onChanged,
    required this.items,
  });

  final void Function(String?)? onChanged;
  final List<Wilaya> items;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      hint: Text(
        "selectWilayaLabel".tr(context),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: context.isDarkMode ? AppColors.primary : AppColors.secondaryLight,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        label: Text("wilayaLabel".tr(context)),
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
      items: items.map((Wilaya wilaya) {
        return DropdownMenuItem<String>(
          value: wilaya.code,
          child: Text(
            context.isArabicLocale ? wilaya.arName : wilaya.name.toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
