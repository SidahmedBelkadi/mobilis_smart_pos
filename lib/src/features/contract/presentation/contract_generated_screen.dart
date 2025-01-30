import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/session_timeout.dart';

import '../../../config/routing/app_routes.dart';
import '../../../core/commom/widgets/app_elevated_button_text.dart';
import '../../../core/utils/helpers/app_localization_helper.dart';
import '../../../core/utils/ressources/app_images.dart';

class ContractGenerated extends StatelessWidget {
  const ContractGenerated({super.key});

  @override
  Widget build(BuildContext context) {
    return SessionTimeout(
      child: PopScope(
        canPop: false,
        child: SafeArea(
            child: Scaffold(
          body: Column(
            children: [
              Center(
                  child: Padding(
                padding: EdgeInsets.all(32.sp),
                child: Column(
                  children: [
                    Lottie.asset(AppImages.success, height: 320.h, width: 320.w),
                    Text(
                      "contract_generated_suc".tr(context),
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 80.sp),
                    AppElevatedButtonWithText(
                      text: "home".tr(context),
                      onPressed: () {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          Routes.main,
                          (route) => false,
                        );
                      },
                    )
                  ],
                ),
              )),
            ],
          ),
        )),
      ),
    );
  }
}
