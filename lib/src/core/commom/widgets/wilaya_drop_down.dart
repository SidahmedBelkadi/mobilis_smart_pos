import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../../features/contract/domain/entities/wilaya_entity.dart';

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
    return DropdownSearch<String>(
      decoratorProps: DropDownDecoratorProps(
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 20.h),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          label: Text("wilayaLabel".tr(context)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0.r),
            borderSide: const BorderSide(color: AppColors.inputBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0.r),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0.r),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          errorStyle: TextStyle(fontSize: 10.sp, color: Colors.red, overflow: TextOverflow.visible),
        ),
      ),
      popupProps: PopupProps.menu(
        showSearchBox: true,
        emptyBuilder: (context, searchEntry) {
          return Text("no_search_result".tr(context));
        },
        searchFieldProps: TextFieldProps(
            decoration: InputDecoration(
          label: Text("search".tr(context)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0.r),
            borderSide: const BorderSide(color: AppColors.inputBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0.r),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0.r),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
        )),
        fit: FlexFit.tight,
      ),

      items: (filter, loadProps) {
        return items.map((Wilaya wilaya) {
          return wilaya.code; // Provide the unique code for each Wilaya
        }).toList();
      },
      itemAsString: (String? code) {
        final wilaya = items.firstWhere((wilaya) => wilaya.code == code);
        return context.isArabicLocale ? wilaya.arName : wilaya.name.toUpperCase();
      },
      onChanged: onChanged,
      selectedItem: null,
      // Optionally set the initially selected item
    );
  }
}
