import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:mobilis_smart_pos/src/core/utils/ressources/app_colors.dart';
import 'package:mobilis_smart_pos/src/core/utils/ressources/app_images.dart';
import 'package:mobilis_smart_pos/src/features/bar_code/presentation/ui.dart';

class LoadingBarrier extends StatelessWidget {
  const LoadingBarrier({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SimScannerUI(onPressed: () {}),
        ModalBarrier(
          color: Colors.black.withOpacity(0.3),
          dismissible: false,
        ),
        Center(
          child: Container(
            height: 56.sp,
            width: 56.sp,
            padding: EdgeInsets.all(12.sp),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12.sp),
            ),
            child: LottieBuilder.asset(AppImages.loading),
          ),
        ),
      ],
    );
  }
}
