import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/session_timeout.dart';
import 'package:mobilis_smart_pos/src/features/bar_code/presentation/ui.dart';
import '../../../config/routing/app_routes.dart';
import '../../../core/commom/widgets/custom_appbar_with_deny_contract.dart';
import '../../../core/utils/helpers/app_localization_helper.dart';
import '../../../core/utils/helpers/media_query_values.dart';
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
String? selectedOfferName;

class SimScannerScreenState extends State<SimScannerScreen> {
  static const platform = MethodChannel("channel");

  @override
  void initState() {
    cubit = context.read<ContractCubit>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SessionTimeout(
      child: SafeArea(
        child: Scaffold(
          appBar: _buildBarCodeScreenAppBar(context),
          body: SingleChildScrollView(
            child: SizedBox(
              height: context.height - 56.sp,
              width: context.width,
              child: SimScannerUI(
                onPressed: () => _startBarcodeScanner(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  CustomAppbarWithDenyContract _buildBarCodeScreenAppBar(BuildContext context) {
    return CustomAppbarWithDenyContract(
      title: "scan_sim".tr(context),
      showProgressIndicator: true,
      currentStep: widget.parentRecto != null ? 7 : 4,
      allSteps: widget.parentRecto != null ? 8 : 5,
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
              onPressed: () {
                _continueWithBarcode(context, barcode);
              },
            ),
          ],
        );
      },
    );
  }

  void _continueWithBarcode(BuildContext context, String barcode) {
    final ContractRequestParamsEntitiy newContract = widget.contract.copyWith(
      serialNumber: int.parse(barcode),
    );

    Navigator.of(context).pushNamed(
      Routes.signatureScreen,
      arguments: {
        'contract': newContract,
        'formattedSmsCode':
            '', // TODO : Ask Sarah about this, Cuz now it's empty since we're not doing check before edit
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
}
