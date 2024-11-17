import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import '../../../../core/commom/widgets/custom_app_bar.dart';
import '../../../../core/utils/helpers/app_localization_helper.dart';
import '../../../../core/utils/helpers/media_query_values.dart';
import '../../domain/entities/contract_request_params_entitiy.dart';

import '../../../../config/routing/app_routes.dart';
import '../../../../core/utils/ressources/app_images.dart';
import '../../../../services/nfc_service.dart';

class NfcReaderScreen extends StatefulWidget {
  const NfcReaderScreen({
    super.key,
    required this.documentNumber,
    required this.dateOfBirth,
    required this.dateOfExpiry,
    required this.docType,
    this.isMinor = false,
    this.minorContract,
    this.minorRecto,
    this.minorVerso,
    this.minorIsPassport,
    this.parentIsPassport,
  });

  final String documentNumber;
  final String dateOfBirth;
  final String dateOfExpiry;
  final String docType;
  final bool isMinor;

  final ContractRequestParamsEntitiy? minorContract;
  final File? minorRecto;
  final File? minorVerso;
  final bool? minorIsPassport;
  final bool? parentIsPassport;

  @override
  State<NfcReaderScreen> createState() => _NfcReaderScreenState();
}

class _NfcReaderScreenState extends State<NfcReaderScreen> {
  String? _errorMessage;
  bool _isLoading = false;
  Map<String, dynamic>? _nfcData;

  @override
  void initState() {
    super.initState();
    // Listen for the 'reading_started' event from the Android side
    NFCService.platform.setMethodCallHandler((call) async {
      if (call.method == 'reading_started') {
        setState(() {
          _isLoading = true;
        });
      }
      return;
    });

    _readNfc();
  }

  Future<void> _readNfc() async {
    setState(() {
      _errorMessage = null;
    });

    final nfcService = NFCService();

    final result = await nfcService.readNfc(
      widget.docType,
      widget.documentNumber,
      widget.dateOfBirth,
      widget.dateOfExpiry,
      false,
      false,
    );

    setState(() {
      _isLoading = false;
      if (result.containsKey('error')) {
        _errorMessage = result['error'];
        debugPrint("============== Error during NFC scan: $_errorMessage");
        Navigator.pop(context, _errorMessage);
      } else {
        _nfcData = result;
        debugPrint("NFC DATA : ${_nfcData}");
        widget.minorContract != null
            ? _navigateToParentContract()
            : Navigator.of(context).pushNamed(Routes.contract, arguments: {
                'data': _nfcData,
                'isMinor': widget.isMinor,
                'isPresumed': !RegExp(r'^\d{6}$').hasMatch(widget.dateOfBirth)
              });
      }
    });
  }

  _navigateToParentContract() {
    Navigator.of(context).pushReplacementNamed(Routes.parentContract, arguments: {
      'minorContract': widget.minorContract,
      'minorRecto': widget.minorRecto,
      'minorVerso': widget.minorVerso,
      'minorIsPassport': widget.minorIsPassport,
      'parentIsPassport': widget.parentIsPassport,
      'parentExtractedNFCData': _nfcData
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: CustomAppBar(
          title: "scan_nfc".tr(context),
          showProgressIndicator: true,
          currentStep: widget.minorRecto != null ? 5 : 2,
          allSteps: widget.minorRecto != null ? 8 : 5,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(24.sp),
          child: _isLoading
              ? Container(
                  height: context.height - 200.sp,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const LinearProgressIndicator(),
                      SizedBox(height: 12.sp),
                      Text(
                        'reading'.tr(context),
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 16.sp),
                    const ScanInstruction(),
                    SizedBox(height: 16.sp),
                    LottieBuilder.asset(AppImages.nfc),
                  ],
                ),
        ),
      ),
    );
  }
}

class ScanInstruction extends StatelessWidget {
  const ScanInstruction({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: context.width,
          padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 16.sp),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(.1),
            borderRadius: BorderRadius.all(
              Radius.circular(12.sp),
            ),
          ),
          child: Text(
            "nfcPreparationText".tr(context),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ],
    );
  }
}
