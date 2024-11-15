import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/utils/ressources/app_colors.dart';

class InvoicesCategoryItem extends StatelessWidget {
  const InvoicesCategoryItem({
    super.key,
    required this.text,
    this.isSelected = false,
    this.onTap,
  });

  final String text;
  final bool isSelected;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36.sp,
        padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 8.sp),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.sp),
          color: isSelected ? AppColors.primary : const Color.fromARGB(255, 229, 251, 212),
        ),
        child: Center(
          child: Text(
            text,
            style: isSelected
                ? Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    )
                : Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: AppColors.categoryTextColorGrey,
                    ),
          ),
        ),
      ),
    );
  }
}
