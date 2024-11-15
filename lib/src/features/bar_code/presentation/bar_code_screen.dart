import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:mobilis_smart_pos/src/core/commom/widgets/custom_appbar_with_deny_contract.dart';

import '../../../config/routing/app_routes.dart';
import '../../../core/commom/widgets/app_elevated_button_text.dart';
import '../../../core/utils/helpers/app_localization_helper.dart';
import '../../../core/utils/helpers/media_query_values.dart';
import '../../../core/utils/helpers/toast_helper.dart';
import '../../../core/utils/ressources/app_colors.dart';
import '../../../core/utils/ressources/app_images.dart';
import '../../contract/domain/entities/contract_request_params_entitiy.dart';
import '../../contract/presentation/cubit/contract_cubit.dart';

class SimScannerScreen extends StatefulWidget {
  const SimScannerScreen({
    super.key,
    required this.contract,
    this.recto,
    this.verso,
    required this.isPassport,
    this.parentRecto,
    this.parentVerso,
    this.justificatif,
    this.parentIsPassport,
  });

  final ContractRequestParamsEntitiy contract;
  final File? recto;
  final File? verso;
  final bool isPassport;
  final File? parentRecto;
  final File? parentVerso;
  final File? justificatif;
  final bool? parentIsPassport;

  @override
  SimScannerScreenState createState() => SimScannerScreenState();
}

late ContractCubit cubit;
late ContractRequestParamsEntitiy newContract;

class SimScannerScreenState extends State<SimScannerScreen> {
  @override
  void initState() {
    debugPrint(
        "=============================== JUSTIFICATIF : ${widget.justificatif}");
    cubit = context.read<ContractCubit>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: CustomAppbarWithDenyContract(
          title: "scan_sim".tr(context),
          showProgressIndicator: true,
          currentStep: widget.parentRecto != null ? 7 : 4,
          allSteps: widget.parentRecto != null ? 8 : 5,
        ),
        body: SingleChildScrollView(
          child: SizedBox(
            height: context.height - 56.sp,
            width: context.width,
            child: BlocConsumer<ContractCubit, ContractState>(
              listener: (context, state) {
                if (state is CheckBeforeEditContractSuccess) {
                  Navigator.of(context).pushNamed(
                    Routes.signatureScreen,
                    arguments: {
                      'contract': newContract,
                      'formattedSmsCode': state.formattedStringWithoutSpaces,
                      'recto': widget.recto,
                      'verso': widget.verso,
                      'isPassport': widget.isPassport,
                      'parentRecto': widget.parentRecto,
                      'parentVerso': widget.parentVerso,
                      'justificatif': widget.justificatif,
                      'parentIsPassport': widget.parentIsPassport
                    },
                  );
                }
                if (state is CheckBeforeEditContractFailed) {
                  AppToasts.showErrorToast(
                    message: state.message.tr(context),
                    context: context,
                  );
                }
              },
              builder: (context, state) {
                if (state is CheckBeforeEditContractLoading) {
                  return Stack(
                    children: [
                      SimScannerBody(onPressed: () {}),
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
                return SimScannerBody(
                  onPressed: () {
                    _scanBarCode(context);
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _scanBarCode(BuildContext context) async {
    String barCodeScanRes;
    do {
      try {
        barCodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          "#91ff59",
          "discard".tr(context),
          true,
          ScanMode.BARCODE,
        );

        if (barCodeScanRes == "-1") {
          // User pressed cancel
          return;
        }

        // Regex to check if the barcode is 13 characters long
        RegExp regex = RegExp(r'\d{13}$');

        if (regex.hasMatch(barCodeScanRes)) {
          if (barCodeScanRes.startsWith("892130")) {
            AppToasts.showErrorToast(
                message: "Please scan the innner bar code of the sim",
                context: context);
            return;
          }

          _showBarcodeDialog(context, barCodeScanRes);
          return;
        }
        // If the barcode is not valid, continue scanning
      } on PlatformException catch (e) {
        debugPrint(
            "================= PlatformException during barcode scan: ${e.message}");
        AppToasts.showErrorToast(
          message: "================= Error opening scanner: ${e.message}",
          context: context,
        );
      }
    } while (true);
  }

  Future<void> _showBarcodeDialog(BuildContext context, String barcode) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button to dismiss the dialog
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('scanned_bar_code'.tr(context)),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  barcode,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                SizedBox(height: 16.h),
                Text('scanned_bar_code_question'.tr(context)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('discard'.tr(context)),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
            ),
            ElevatedButton(
              child: Text('yes'.tr(context)),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
                _continueWithBarcode(
                    context, barcode); // Continue with the operation
              },
            ),
          ],
        );
      },
    );
  }

  void _continueWithBarcode(BuildContext context, String barcode) {
    setState(() {
      newContract = widget.contract.copyWith(serialNumber: int.parse(barcode));
    });

    cubit.checkBeforeEditContract(
      contract: newContract,
    );
  }
}

class SimScannerBody extends StatelessWidget {
  const SimScannerBody({super.key, this.onPressed});

  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.height,
      width: context.width,
      padding: EdgeInsets.all(32.sp),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(AppImages.barCodeAnimation5,
              height: 200.h, width: 200.w),
          SizedBox(height: 32.h),
          Text(
            "bar_code_instruction".tr(context),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  color: AppColors.primary,
                ),
          ),
          SizedBox(height: 64.h),
          AppElevatedButtonWithText(
            text: "start_button".tr(context),
            onPressed: onPressed,
          )
        ],
      ),
    );
  }
}
