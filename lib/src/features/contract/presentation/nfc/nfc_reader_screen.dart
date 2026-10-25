import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/session_timeout.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/toast_helper.dart';
import '../../../../core/commom/widgets/custom_app_bar.dart';
import '../../../../core/utils/helpers/app_localization_helper.dart';
import '../../../../core/utils/helpers/media_query_values.dart';
import '../../domain/entities/contract_request_params_entitiy.dart';

import '../../../../config/routing/app_routes.dart';
import '../../../../core/utils/ressources/app_colors.dart';
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

enum _NfcStage { waiting, reading, interrupted, failed }

class _NfcReaderScreenState extends State<NfcReaderScreen> {
  _NfcStage _stage = _NfcStage.waiting;
  double _progress = 0;
  String _step = 'AUTH';
  int _interruptions = 0;

  /// Error code of a definitive failure (BAC_FAILED, NFC_READ_ERROR).
  String? _failureCode;
  Map<String, dynamic>? _nfcData;

  @override
  void initState() {
    super.initState();
    // Events sent by the Android side while the document is on the phone
    NFCService.platform.setMethodCallHandler((call) async {
      if (!mounted) return;
      switch (call.method) {
        case 'reading_started':
          setState(() {
            _stage = _NfcStage.reading;
            _progress = 0;
          });
          break;
        case 'reading_progress':
          final args = Map<String, dynamic>.from(call.arguments as Map);
          setState(() {
            _stage = _NfcStage.reading;
            _progress = (args['progress'] as int) / 100;
            _step = args['step'] as String;
          });
          break;
        case 'reading_interrupted':
          // The session stays open: the user just puts the document back
          HapticFeedback.mediumImpact();
          setState(() {
            _stage = _NfcStage.interrupted;
            _interruptions++;
          });
          break;
      }
    });

    _readNfc();
  }

  @override
  void dispose() {
    // Leaving the screen (back, session timeout): stop waiting for the card
    if (_nfcData == null) NFCService.cancel();
    super.dispose();
  }

  Future<void> _readNfc() async {
    setState(() {
      _stage = _NfcStage.waiting;
      _failureCode = null;
      _progress = 0;
      _interruptions = 0;
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
    if (!mounted) return;

    if (result.containsKey('error')) {
      final code = result['code'] as String?;
      if (code == 'CANCELLED') return;
      if (code == 'BAC_FAILED' || code == 'NFC_READ_ERROR') {
        // Same document, same MRZ: the agent can try again or rescan the document
        HapticFeedback.heavyImpact();
        setState(() {
          _stage = _NfcStage.failed;
          _failureCode = code;
        });
        return;
      }
      // DOCUMENT_NOT_AUTHENTIC and unexpected errors: back to the document scan, as before
      _goBackToDocumentScan();
      return;
    }

    _nfcData = result;
    debugPrint("NFC DATA : $_nfcData");
    widget.minorContract != null
        ? _navigateToParentContract()
        : Navigator.of(context).pushReplacementNamed(Routes.contract, arguments: {
            'data': _nfcData,
            'isMinor': widget.isMinor,
            'isPresumed': !RegExp(r'^\d{6}$').hasMatch(widget.dateOfBirth)
          });
  }

  void _goBackToDocumentScan() {
    AppToasts.showWarningToast(
      message: "try_scan_doc_again".tr(context),
      context: context,
    );
    Navigator.of(context).pushNamedAndRemoveUntil(
      Routes.main,
      (route) => false,
      arguments: {
        'index': 1,
      },
    );
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
    return SessionTimeout(
      child: Scaffold(
        appBar: CustomAppBar(
          title: "scan_nfc".tr(context),
          showProgressIndicator: true,
          currentStep: widget.minorRecto != null ? 5 : 2,
          allSteps: widget.minorRecto != null ? 8 : 5,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(24.sp),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: switch (_stage) {
              _NfcStage.waiting => _buildWaiting(),
              _NfcStage.reading => _buildReading(),
              _NfcStage.interrupted => _buildInterrupted(),
              _NfcStage.failed => _buildFailed(),
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWaiting() {
    return Column(
      key: const ValueKey('waiting'),
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 16.sp),
        const ScanInstruction(),
        SizedBox(height: 16.sp),
        LottieBuilder.asset(AppImages.nfc),
      ],
    );
  }

  Widget _buildReading() {
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey('reading'),
      height: context.height - 200.sp,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animates between the values sent by the chip reader
          TweenAnimationBuilder<double>(
            tween: Tween(end: _progress),
            duration: const Duration(milliseconds: 300),
            builder: (context, value, _) => SizedBox(
              width: 140.sp,
              height: 140.sp,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: value,
                    strokeWidth: 10.sp,
                    backgroundColor: AppColors.primary.withOpacity(.15),
                    color: AppColors.primary,
                  ),
                  Center(
                    child: Text(
                      '${(value * 100).round()}%',
                      style: theme.textTheme.headlineSmall!.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24.sp),
          Text(
            _stepLabel().tr(context),
            style: theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.sp),
          Text(
            'reading'.tr(context),
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _stepLabel() => switch (_step) {
        'READ' => 'nfc_step_read',
        'VERIFY' => 'nfc_step_verify',
        _ => 'nfc_step_auth',
      };

  Widget _buildInterrupted() {
    final theme = Theme.of(context);
    return Column(
      key: ValueKey('interrupted$_interruptions'),
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 16.sp),
        _Banner(
          color: Colors.orange,
          icon: Icons.nfc,
          title: 'nfc_connection_lost_title'.tr(context),
          message: 'nfc_connection_lost_message'.tr(context),
        ),
        if (_progress > 0) ...[
          SizedBox(height: 16.sp),
          LinearProgressIndicator(
            value: _progress,
            minHeight: 6.sp,
            borderRadius: BorderRadius.circular(6.sp),
            backgroundColor: Colors.orange.withOpacity(.15),
            color: Colors.orange,
          ),
          SizedBox(height: 6.sp),
          Text(
            '${(_progress * 100).round()}%',
            style: theme.textTheme.bodySmall!.copyWith(color: Colors.orange),
          ),
        ],
        SizedBox(height: 16.sp),
        LottieBuilder.asset(AppImages.nfc),
        SizedBox(height: 8.sp),
        TextButton(
          onPressed: _goBackToDocumentScan,
          child: Text('nfc_rescan_document'.tr(context)),
        ),
      ],
    );
  }

  Widget _buildFailed() {
    return Column(
      key: const ValueKey('failed'),
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 32.sp),
        _Banner(
          color: Colors.red,
          icon: Icons.error_outline,
          title: 'nfc_read_failed_title'.tr(context),
          message: (_failureCode == 'BAC_FAILED' ? 'nfc_bac_failed_message' : 'nfc_read_failed_message')
              .tr(context),
        ),
        SizedBox(height: 32.sp),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _readNfc,
            icon: const Icon(Icons.refresh),
            label: Text('retry'.tr(context)),
          ),
        ),
        SizedBox(height: 12.sp),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _goBackToDocumentScan,
            icon: const Icon(Icons.document_scanner_outlined),
            label: Text('nfc_rescan_document'.tr(context)),
          ),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.color, required this.icon, required this.title, required this.message});

  final Color color;
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: context.width,
      padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 16.sp),
      decoration: BoxDecoration(
        color: color.withOpacity(.1),
        borderRadius: BorderRadius.all(Radius.circular(12.sp)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32.sp),
          SizedBox(height: 8.sp),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium!.copyWith(color: color, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6.sp),
          Text(message, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
        ],
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
