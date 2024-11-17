import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/helpers/media_query_values.dart';

import '../../utils/ressources/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    required this.title,
    this.action,
    this.onTap,
    this.showProgressIndicator,
    this.currentStep,
    this.allSteps,
  });

  final String title;
  final IconData? action;
  final Function()? onTap;
  final bool? showProgressIndicator;
  final int? currentStep;
  final int? allSteps;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBar(
          centerTitle: true,
          foregroundColor: Colors.black,
          backgroundColor: AppColors.primary,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge!
                      .copyWith(fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ),
              if (showProgressIndicator != null)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0.sp),
                  child: Text(
                    "($currentStep/$allSteps)",
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
            ],
          ),
          actions: action != null
              ? [
                  InkWell(
                    onTap: onTap,
                    child: Padding(
                      padding: context.isArabicLocale
                          ? EdgeInsets.only(left: 12.0.sp)
                          : EdgeInsets.only(right: 12.0.sp),
                      child: Icon(
                        action,
                        size: 20.sp,
                      ),
                    ),
                  )
                ]
              : [],
        ),
        if (showProgressIndicator != null)
          LinearProgressIndicator(
            value: currentStep! / allSteps!,
          )
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(60.sp);
}
