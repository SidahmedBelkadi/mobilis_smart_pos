import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/helpers/app_localization_helper.dart';

import '../../../config/routing/app_routes.dart';
import '../../utils/ressources/app_colors.dart';

class CustomAppbarWithDenyContract extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppbarWithDenyContract({
    super.key,
    required this.title,
    this.showProgressIndicator,
    this.currentStep,
    this.allSteps,
    this.actionTitle = "discard_activation",
  });

  final String title;
  final bool? showProgressIndicator;
  final int? currentStep;
  final int? allSteps;
  final String actionTitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBar(
          foregroundColor: Colors.black,
          backgroundColor: AppColors.primary,
          centerTitle: true,
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
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {},
              itemBuilder: (context) {
                return [
                  PopupMenuItem<String>(
                    onTap: () {
                      Navigator.of(context).pushNamedAndRemoveUntil(Routes.main, (route) => false);
                    },
                    value: 'cancel',
                    child: Text(actionTitle.tr(context)),
                  ),
                ];
              },
            ),
          ],
        ),
        if (showProgressIndicator != null)
          if ((currentStep! / allSteps!) != 1)
            LinearProgressIndicator(
              value: currentStep! / allSteps!,
              color: AppColors.secondary,
            )
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(60.sp);
}
