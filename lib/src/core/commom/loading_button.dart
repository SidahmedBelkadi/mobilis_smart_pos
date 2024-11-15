import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';

import '../../features/sign_in/presentation/widgets/elevated_button.dart';
import '../utils/ressources/app_images.dart';

class LoadingButton extends StatelessWidget {
  const LoadingButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SignInElevatedButton(
      onPressed: () {},
      isLoading: true,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 0, vertical: 8.sp),
        child: Lottie.asset(AppImages.loading, height: 48.sp, width: 48.sp),
      ),
    );
  }
}
