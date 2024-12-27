import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:mobilis_smart_pos/src/core/commom/widgets/app_elevated_button_text.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/app_localization_helper.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/media_query_values.dart';
import 'package:mobilis_smart_pos/src/core/utils/ressources/app_colors.dart';
import 'package:mobilis_smart_pos/src/core/utils/ressources/app_images.dart';

class SimScannerUI extends StatelessWidget {
  const SimScannerUI({super.key, this.onPressed});

  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.height,
      width: context.width,
      padding: EdgeInsets.all(32.sp),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(AppImages.barCodeAnimation5, height: 200.h, width: 200.w),
          SizedBox(height: 32.h),
          Text(
            "bar_code_instruction".tr(context),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  color: AppColors.primary,
                ),
          ),
          SizedBox(height: 64.h),
          AppElevatedButtonWithText(
            text: "start_button".tr(context),
            onPressed: onPressed,
          )
        ],
      ),
    );
  }
}
