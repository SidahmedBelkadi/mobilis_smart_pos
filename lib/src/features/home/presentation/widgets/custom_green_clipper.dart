import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/media_query_values.dart';
import 'package:mobilis_smart_pos/src/core/utils/ressources/app_colors.dart';
import 'package:mobilis_smart_pos/src/features/home/presentation/widgets/CustomCuvedEdges.dart';
import 'package:mobilis_smart_pos/src/features/home/presentation/widgets/custom_pos_app_bar.dart';

class CustomGreenClipper extends StatelessWidget {
  const CustomGreenClipper({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: Customcuvededges(),
      child: Container(
        height: 120.sp,
        color: AppColors.primary,
        child: SizedBox(
          width: context.width,
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: CustomPosAppBar(),
          ),
        ),
      ),
    );
  }
}
