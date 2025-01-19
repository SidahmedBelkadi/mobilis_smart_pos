import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:json_pretty/json_pretty.dart';
import 'package:lottie/lottie.dart';
import 'package:mobilis_smart_pos/src/config/routing/app_routes.dart';
import 'package:mobilis_smart_pos/src/core/commom/widgets/app_elevated_button_text.dart';
import 'package:mobilis_smart_pos/src/core/commom/widgets/custom_app_bar.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/app_localization_helper.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/media_query_values.dart';
import 'package:mobilis_smart_pos/src/core/utils/ressources/app_colors.dart';
import 'package:mobilis_smart_pos/src/core/utils/ressources/app_images.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/rasd_request_params_entity.dart';

class RasdBarCodeScanner extends StatefulWidget {
  const RasdBarCodeScanner({super.key, required this.rasdParams});

  final RasdRequestParamsEntity rasdParams;

  @override
  State<RasdBarCodeScanner> createState() => _RasdBarCodeScannerState();
}

class _RasdBarCodeScannerState extends State<RasdBarCodeScanner> {
  static const platform = MethodChannel("channel");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Scanner'),
      body: Container(
        height: context.height,
        width: context.width,
        padding: EdgeInsets.all(32.sp),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(AppImages.barCodeAnimation5, height: 200.h, width: 200.w),
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
              onPressed: () => _startBarcodeScanner(context),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _startBarcodeScanner(BuildContext context) async {
    try {
      final result = await platform.invokeMethod("startBarcodeScanner");
      if (context.mounted) {
        _showBarcodeDialog(context, result);
      }
    } on PlatformException catch (e) {
      debugPrint("Bar code exception : $e");
      return;
    }
  }

  Future<void> _showBarcodeDialog(BuildContext context, String barcode) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
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
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('yes'.tr(context)),
              onPressed: () async {
                Navigator.of(context).pop();
                final Map? selectedOffer =
                    await Navigator.of(context).pushNamed(Routes.offers) as Map?;
                debugPrint("======== SELECTED OFFER ! $selectedOffer");

                if (selectedOffer != null) {
                  final params = widget.rasdParams.copyWith(
                    serialNumber: int.parse(barcode),
                    subscriptionTypeId: selectedOffer['offerId'],
                  );
                  debugPrint(prettyPrintJson(jsonEncode(params.toJson())));
                  _navigateToSignatureScreen();
                }
              },
            ),
          ],
        );
      },
    );
  }

  _navigateToSignatureScreen() {
    Navigator.of(context).pushNamed(Routes.rasdBarSignatureSCreen);
  }
}
