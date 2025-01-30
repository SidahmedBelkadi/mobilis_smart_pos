import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/session_timeout.dart';
import 'package:mobilis_smart_pos/src/services/nfc_service.dart';
import '../../../../core/commom/widgets/custom_floating_action_button.dart';
import '../../../../core/utils/helpers/dialog_helper.dart';
import '../../../../services/screenshot_service.dart';

import '../../../../config/routing/app_routes.dart';
import '../../../../core/commom/widgets/app_text_form_field.dart';
import '../../../../core/commom/widgets/custom_app_bar.dart';
import '../../../../core/utils/helpers/app_localization_helper.dart';
import '../../../../core/utils/helpers/media_query_values.dart';
import '../../../../core/utils/helpers/toast_helper.dart';

class MrzDetailsScreen extends StatefulWidget {
  const MrzDetailsScreen({
    super.key,
    required this.documentNumber,
    required this.dateOfBirth,
    required this.dateOfExpiry,
    required this.docType,
  });

  final String documentNumber;
  final String dateOfBirth;
  final String dateOfExpiry;
  final String docType;

  @override
  MrzDetailsScreenState createState() => MrzDetailsScreenState();
}

class MrzDetailsScreenState extends State<MrzDetailsScreen> {
  late TextEditingController documentNumberController;
  late TextEditingController birthDateController;
  late TextEditingController expirationDateController;

  bool isExpired = false;
  bool isMinor = false;

  @override
  void initState() {
    super.initState();

    ScreenshotService.preventScreenshotOn();

    _compareDates();

    documentNumberController = TextEditingController();
    birthDateController = TextEditingController();
    expirationDateController = TextEditingController();
  }

  @override
  void dispose() {
    documentNumberController.dispose();
    birthDateController.dispose();
    expirationDateController.dispose();
    ScreenshotService.preventScreenshotOff();

    super.dispose();
  }

  void _compareDates() {
    try {
      final expirationDate = widget.dateOfExpiry;
      final birthDate = widget.dateOfBirth;

      final expirationDateParsed = _parseDate(expirationDate, true);
      final currentDate = DateTime.now();

      if (expirationDateParsed.isBefore(currentDate)) {
        setState(() {
          isExpired = true;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppToasts.showErrorToast(
            message: "card_expired".tr(context),
            context: context,
            onAutoCompleteCompleted: (p0) => Navigator.of(context).pushNamedAndRemoveUntil(
              Routes.main,
              (route) => false,
            ),
          );
        });
      }

      final birthDateParsed = _parseDate(birthDate, false);
      final age = currentDate.year - birthDateParsed.year;

      if (age < 19 ||
          (age == 19 &&
              currentDate.isBefore(birthDateParsed.add(const Duration(days: 365 * 19))))) {
        setState(() {
          isMinor = true;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppDialog.showCustomAppDialog(
            title: "client_is_minor_title".tr(context),
            content: "client_is_minor_instruction".tr(context),
            acceptName: "yes",
            discardName: "no",
            onPressed: () => Navigator.of(context).pushNamed(Routes.nfcReader, arguments: {
              'documentNumber': widget.documentNumber,
              'dateOfBirth': widget.dateOfBirth,
              'dateOfExpiry': widget.dateOfExpiry,
              'docType': widget.docType,
              'isMinor': true
            }),
            context: context,
          );
        });
      }
    } catch (e) {
      return;
    }
  }

  DateTime _parseDate(String date, bool isExpiryDate) {
    if (RegExp(r'^\d{6}$').hasMatch(date)) {
      final year = int.parse(date.substring(0, 2));
      final month = int.parse(date.substring(2, 4));
      final day = int.parse(date.substring(4, 6));

      final currentYear = DateTime.now().year;
      final century = (year + 2000 <= currentYear) ? 2000 : 1900;

      return DateTime(isExpiryDate ? 2000 + year : century + year, month, day);
    } else if (RegExp(r'^\d{2}<<<<').hasMatch(date)) {
      final year = int.parse(date.substring(0, 2));

      final currentYear = DateTime.now().year;
      final century = (year + 2000 <= currentYear) ? 2000 : 1900;

      return DateTime(century + year, 1, 1);
    }

    throw const FormatException("format exception");
  }

  @override
  Widget build(BuildContext context) {
    return SessionTimeout(
      child: SafeArea(
        child: Scaffold(
          appBar: CustomAppBar(
            title: "mrzScanResultTitle".tr(context),
            showProgressIndicator: true,
            currentStep: 1,
            allSteps: isMinor ? 8 : 5,
          ),
          floatingActionButton: isExpired || isMinor
              ? null
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: context.isArabicLocale
                          ? EdgeInsets.only(right: 32.sp)
                          : EdgeInsets.only(left: 32.sp),
                      child: CustomFAB(
                        label: '',
                        icon: Icons.repeat,
                        heroTag: 're-scan',
                        onPressed: () {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            Routes.main,
                            arguments: {'index': 1},
                            (route) => false,
                          );
                        },
                      ),
                    ),
                    CustomFAB(
                      label: "continuer".tr(context),
                      icon: context.isArabicLocale
                          ? CupertinoIcons.chevron_left
                          : CupertinoIcons.chevron_right,
                      heroTag: 'continue-to-nfc',
                      onPressed: () async {
                        final isNFcEnabled = await NFCService.isNfcEnabled();
                        if (!isNFcEnabled) {
                          AppToasts.showWarningToast(
                            message: "enable_nfc".tr(context),
                            context: context,
                          );
                          return;
                        }
                        Navigator.of(context).pushReplacementNamed(Routes.nfcReader, arguments: {
                          'documentNumber': widget.documentNumber,
                          'dateOfBirth': widget.dateOfBirth,
                          'dateOfExpiry': widget.dateOfExpiry,
                          'docType': widget.docType,
                          'isMinor': false
                        });
                      },
                    ),
                  ],
                ),
          body: SingleChildScrollView(
            child: Container(
              width: context.width,
              height: context.height - 200.h,
              padding: EdgeInsets.all(32.sp),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const ScanInstruction(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          AppTextFormField(
                            label: "documentNumberLabel".tr(context),
                            textEditingController: documentNumberController,
                            enabled: false,
                            disabledValue: widget.documentNumber,
                          ),
                          SizedBox(height: 16.h),
                          AppTextFormField(
                            label: "birthDateLabel".tr(context),
                            textEditingController: birthDateController,
                            enabled: false,
                            disabledValue: widget.dateOfBirth,
                          ),
                          SizedBox(height: 16.h),
                          AppTextFormField(
                            label: "expirationDateLabel".tr(context),
                            textEditingController: expirationDateController,
                            enabled: false,
                            disabledValue: widget.dateOfExpiry,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
            "mrz_result_instruction".tr(context),
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
