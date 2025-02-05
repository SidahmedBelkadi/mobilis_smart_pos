import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobilis_smart_pos/src/config/routing/app_routes.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/app_localization_helper.dart';
import 'package:mobilis_smart_pos/src/core/utils/ressources/app_images.dart';
import 'package:mobilis_smart_pos/src/features/home/presentation/widgets/home_icon_widget.dart';

class HomeIcons extends StatelessWidget {
  const HomeIcons({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            HomeIcon(
              onTap: () => {},
              image: AppImages.paymentFactures,
              title: "mesFactures".tr(context),
            ),
            SizedBox(width: 32.sp),
            HomeIcon(
              image: AppImages.ereselli,
              title: "erselli".tr(context),
              onTap: () {},
            ),
          ],
        ),
        SizedBox(height: 24.h),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            HomeIcon(
              image: AppImages.activations,
              title: "mesActivations".tr(context),
              onTap: () =>
                  Navigator.of(context).pushReplacementNamed(Routes.main, arguments: {'index': 1}),
            ),
            SizedBox(width: 32.sp),
            HomeIcon(
              image: AppImages.operations,
              title: "mesOperations".tr(context),
              onTap: () => Navigator.of(context).pushNamed(Routes.invoices),
            ),
          ],
        ),
      ],
    );
  }
}
