import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:mobilis_smart_pos/src/config/routing/app_routes.dart';
import 'package:mobilis_smart_pos/src/core/commom/widgets/app_elevated_button_text.dart';
import 'package:mobilis_smart_pos/src/core/commom/widgets/custom_appbar_with_deny_contract.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/app_localization_helper.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/media_query_values.dart';
import 'package:mobilis_smart_pos/src/core/utils/ressources/app_images.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/contract_request_params_entitiy.dart';

class ParentPreparationScreen extends StatelessWidget {
  const ParentPreparationScreen({
    super.key,
    required this.contract,
    this.recto,
    this.verso,
    required this.isPassport,
  });

  final ContractRequestParamsEntitiy contract;
  final File? recto;
  final File? verso;
  final bool isPassport;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppbarWithDenyContract(title: "step02_parent".tr(context)),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(24.sp),
            height: context.height - 100.sp,
            width: context.width,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                LottieBuilder.asset(AppImages.minors),
                SizedBox(height: 24.sp),
                Text(
                  "parent_preparation_instruction".tr(context),
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 64.sp),
                Column(
                  children: [
                    AppElevatedButtonWithText(
                      text: "identityCard".tr(context),
                      onPressed: () {
                        Navigator.of(context)
                            .pushNamed(Routes.parentMrzOcr, arguments: {
                          'documentType': 'id_card',
                          'minorContract': contract,
                          'minorRecto': recto,
                          'minorVerso': verso,
                          'minorIsPassport': isPassport,
                          'parentIsPassport': false,
                        });
                      },
                    ),
                    SizedBox(height: 16.h),
                    AppElevatedButtonWithText(
                      text: "passport".tr(context),
                      onPressed: () {
                        Navigator.of(context)
                            .pushNamed(Routes.parentMrzOcr, arguments: {
                          'documentType': 'passport',
                          'minorContract': contract,
                          'minorRecto': recto,
                          'minorVerso': verso,
                          'minorIsPassport': isPassport,
                          'parentIsPassport': true,
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
