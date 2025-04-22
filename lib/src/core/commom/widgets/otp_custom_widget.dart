import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pinput/pinput.dart';

import '../../utils/helpers/media_query_values.dart';
import '../../utils/ressources/app_colors.dart';

class OTPCustomWidget extends StatelessWidget {
  const OTPCustomWidget({
    super.key,
    this.onCompleted,
    this.controller,
  });

  final void Function(String)? onCompleted;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    final focusedBorderColor = AppColors.primary;
    final fillColor = context.isDarkMode ? Colors.black : const Color.fromRGBO(243, 246, 249, 0);
    final borderColor = AppColors.secondary;

    final defaultPinTheme = PinTheme(
      width: 60.sp,
      height: 60.sp,
      textStyle: TextStyle(
        fontSize: 16.sp,
        color: context.isDarkMode ? AppColors.primary : const Color.fromRGBO(30, 60, 87, 1),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(19.sp),
        border: Border.all(color: borderColor),
      ),
    );

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Pinput(
        // readOnly: true,
        controller: controller,
        length: 6,
        obscureText: false,
        autofocus: false,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '';
          } else if (value.length != 6) {
            return '';
          } else if (!RegExp(r'^\d+$').hasMatch(value)) {
            return '';
          }
          return null;
        },
        hapticFeedbackType: HapticFeedbackType.heavyImpact,
        focusedPinTheme: defaultPinTheme.copyWith(
          decoration: defaultPinTheme.decoration!.copyWith(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: focusedBorderColor, width: 2),
          ),
        ),
        submittedPinTheme: defaultPinTheme.copyWith(
          decoration: defaultPinTheme.decoration!.copyWith(
            color: fillColor,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: focusedBorderColor, width: 2),
          ),
        ),
        errorPinTheme: defaultPinTheme.copyBorderWith(
          border: Border.all(color: Colors.redAccent),
        ),
        followingPinTheme: defaultPinTheme.copyWith(
          decoration: defaultPinTheme.decoration!.copyWith(
            color: fillColor,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: focusedBorderColor, width: 2),
          ),
        ),
        onCompleted: onCompleted,
      ),
    );
  }
}
