import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/media_query_values.dart';
import 'package:mobilis_smart_pos/src/core/utils/ressources/app_colors.dart';
import 'package:skeletonizer/skeletonizer.dart';

class BannersSkeleton extends StatelessWidget {
  const BannersSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: SizedBox(
        height: 220.sp,
        width: context.width,
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16.0.sp),
              child: Container(
                width: context.width,
                height: 190.h, // Ensure same height as banners
                color: context.isDarkMode
                    ? AppColors.darkerGrey
                    : AppColors.grey, // Skeleton background color
              ),
            ),
            SizedBox(height: 24.0.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                4,
                (index) => Container(
                  height: 6.h,
                  width: index == 0 ? 30.w : 8.w,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  decoration: BoxDecoration(
                    color: context.isDarkMode ? AppColors.darkerGrey : AppColors.grey,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
