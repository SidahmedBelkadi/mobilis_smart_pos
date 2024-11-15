import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/utils/helpers/media_query_values.dart';

class SignInElevatedButton extends StatelessWidget {
  const SignInElevatedButton({
    super.key,
    required this.child,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
  });

  final Widget child;
  final void Function()? onPressed;
  final bool isLoading;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: !isLoading && !isDisabled ? context.width : null,
      height: 56.h,
      child: ElevatedButton(
        onPressed: (isLoading || isDisabled) ? () {} : onPressed,
        child: isLoading || isDisabled
            ? SizedBox(
                width: 24.w,
                height: 24.h,
                child: const CircularProgressIndicator(
                  strokeWidth: 4,
                  color: Colors.white,
                ),
              )
            : child,
      ),
    );
  }
}
