import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:mobilis_smart_pos/src/core/commom/widgets/custom_floating_action_button.dart';

import '../../../../config/routing/app_routes.dart';
import '../../../../core/commom/widgets/custom_app_bar.dart';
import '../../../../core/utils/helpers/app_localization_helper.dart';
import '../../../../core/utils/helpers/media_query_values.dart';
import '../../../../core/utils/ressources/app_colors.dart';
import '../../../../core/utils/ressources/app_images.dart';

class MrzPreparationScreen extends StatelessWidget {
  const MrzPreparationScreen({super.key, required this.isPassport});

  final bool isPassport;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        floatingActionButton: CustomFAB(
          label: "continuer".tr(context),
          icon: CupertinoIcons.right_chevron,
          onPressed: () {
            Navigator.of(context).pushNamed(Routes.mrzOcr, arguments: {
              'documentType': isPassport ? 'passport' : 'id_card',
            });
          },
        ),
        appBar: CustomAppBar(title: "mrz_band_scan".tr(context)),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(32.0.sp, 32.0.sp, 32.0.sp, 96.0.sp),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title
                Text(
                  "mrz_get_ready".tr(context),
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),

                // Instructional text
                BuildText(text: "mrz_instruction_1".tr(context)),
                SizedBox(height: 12.h),
                BuildText(text: "mrz_instruction_2".tr(context)),
                SizedBox(height: 12.h),
                BuildText(text: "mrz_instruction_3".tr(context)),

                SizedBox(height: 32.h),

                // Lottie animation
                Lottie.asset(
                  AppImages.mrz,
                  height: 240.h,
                  width: 240.w,
                ),

                SizedBox(height: 32.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BuildText extends StatelessWidget {
  const BuildText({
    super.key,
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium,
      textAlign: context.isArabicLocale ? TextAlign.right : TextAlign.left,
    );
  }
}
