import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:mobilis_smart_pos/src/services/native_ocr.dart';
import '../../../config/routing/app_routes.dart';
import '../../../core/commom/widgets/app_elevated_button_text.dart';
import '../../../core/commom/widgets/custom_appbar_with_deny_contract.dart';
import '../../../core/utils/helpers/app_localization_helper.dart';
import '../../../core/utils/helpers/media_query_values.dart';
import '../../../core/utils/ressources/app_images.dart';
import '../domain/entities/contract_request_params_entitiy.dart';

class ParentPreparationScreen extends StatefulWidget {
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
  State<ParentPreparationScreen> createState() => _ParentPreparationScreenState();
}

class _ParentPreparationScreenState extends State<ParentPreparationScreen> {
  late String documentNumber;
  late String dateOfBirth;
  late String dateOfExpiry;
  late String docType;

  @override
  Widget build(BuildContext context) {
    Future<void> startOCR({required String docType}) async {
      final result = await NativeOCR.startOCR(docType: docType);
      debugPrint("========== RESULT : $result");

      if (result != null) {
        debugPrint("================= DOCUMENT NUMBER : ${result['documentNumber']}");
        debugPrint("================= BIRTH DATE : ${result['birthDate']}");
        debugPrint("================= EXPIRY DATE : ${result['expiredDate']}");
        setState(() {
          documentNumber = result['documentNumber']!;
          dateOfBirth = result['birthDate']!;
          dateOfExpiry = result['expiredDate']!;
        });

        Navigator.of(context).pushReplacementNamed(Routes.parentMrzOcrDetails, arguments: {
          'documentNumber': documentNumber,
          'dateOfBirth': dateOfBirth,
          'dateOfExpiry': dateOfExpiry,
          'docType': docType,
          'documentType': widget.isPassport ? 'passport' : 'id_card',
          'minorContract': widget.contract,
          'minorRecto': widget.recto,
          'minorVerso': widget.verso,
          'minorIsPassport': widget.isPassport,
          'parentIsPassport': docType == "passport",
        });
      }
    }

    return Scaffold(
      appBar: CustomAppbarWithDenyContract(title: "step02_parent".tr(context)),
      body: SingleChildScrollView(
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
                      startOCR(docType: "id_card");
                      // Navigator.of(context).pushNamed(Routes.parentMrzOcr, arguments: {
                      //   'documentType': 'id_card',
                      //   'minorContract': contract,
                      //   'minorRecto': recto,
                      //   'minorVerso': verso,
                      //   'minorIsPassport': isPassport,
                      //   'parentIsPassport': false,
                      // });
                    },
                  ),
                  SizedBox(height: 16.h),
                  AppElevatedButtonWithText(
                    text: "passport".tr(context),
                    onPressed: () {
                      // TODO :
                      startOCR(docType: "passport");
                      // Navigator.of(context).pushNamed(Routes.parentMrzOcr, arguments: {
                      //   'documentType': 'passport',
                      //   'minorContract': contract,
                      //   'minorRecto': recto,
                      //   'minorVerso': verso,
                      //   'minorIsPassport': isPassport,
                      //   'parentIsPassport': true,
                      // });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
