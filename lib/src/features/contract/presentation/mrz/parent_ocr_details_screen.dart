import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../config/routing/app_routes.dart';
import '../../../../core/commom/widgets/app_text_form_field.dart';
import '../../../../core/commom/widgets/custom_app_bar.dart';
import '../../../../core/commom/widgets/custom_floating_action_button.dart';
import '../../../../core/utils/helpers/app_localization_helper.dart';
import '../../../../core/utils/helpers/media_query_values.dart';
import '../../../../core/utils/helpers/toast_helper.dart';
import '../../../../core/utils/ressources/app_colors.dart';
import '../../domain/entities/contract_request_params_entitiy.dart';
import '../../../../services/screenshot_service.dart';

class ParentOcrDetails extends StatefulWidget {
  const ParentOcrDetails({
    super.key,
    required this.documentNumber,
    required this.dateOfBirth,
    required this.dateOfExpiry,
    required this.docType,
    required this.minorContract,
    this.minorRecto,
    this.minorVerso,
    required this.minorIsPassport,
    required this.parentIsPassport,
  });

  final String documentNumber;
  final String dateOfBirth;
  final String dateOfExpiry;
  final String docType;
  final ContractRequestParamsEntitiy minorContract;
  final File? minorRecto;
  final File? minorVerso;
  final bool minorIsPassport;
  final bool parentIsPassport;

  @override
  ParentOcrDetailsState createState() => ParentOcrDetailsState();
}

class ParentOcrDetailsState extends State<ParentOcrDetails> {
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
    super.dispose();
    documentNumberController.dispose();
    birthDateController.dispose();
    expirationDateController.dispose();
    ScreenshotService.preventScreenshotOff();
  }

  void _compareDates() {
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
        );
      });
    }

    final birthDateParsed = _parseDate(birthDate, false);
    final age = currentDate.year - birthDateParsed.year;

    if (age < 19 ||
        (age == 19 && currentDate.isBefore(birthDateParsed.add(const Duration(days: 365 * 19))))) {
      setState(() {
        isMinor = true;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppToasts.showErrorToast(
          message: "invalid_tutor_doc".tr(context),
          context: context,
        );
      });
    }
  }

// Helper function to parse the yymmdd format
  DateTime _parseDate(String date, bool isExpiryDate) {
    // Assuming date format is yymmdd
    final year = int.parse(date.substring(0, 2));
    final month = int.parse(date.substring(2, 4));
    final day = int.parse(date.substring(4, 6));

    // Determine the century (assuming 1900-2099 range)
    final currentYear = DateTime.now().year;
    final century = (year + 2000 <= currentYear) ? 2000 : 1900;

    return DateTime(isExpiryDate ? 2000 + year : century + year, month, day);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "step02_parent_mrz_result".tr(context),
        showProgressIndicator: true,
        currentStep: 4,
        allSteps: 8,
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
                  child: FloatingActionButton(
                    heroTag: 're-scan',
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.black,
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Icon(Icons.repeat),
                  ),
                ),
                CustomFAB(
                    label: "continuer".tr(context),
                    icon: CupertinoIcons.right_chevron,
                    onPressed: () async {
                      Navigator.of(context).pushNamed(Routes.nfcReader, arguments: {
                        'documentNumber': widget.documentNumber,
                        'dateOfBirth': widget.dateOfBirth,
                        'dateOfExpiry': widget.dateOfExpiry,
                        'docType': widget.docType,
                        'isMinor': false,
                        'minorContract': widget.minorContract,
                        'minorRecto': widget.minorRecto,
                        'minorVerso': widget.minorVerso,
                        'minorIsPassport': widget.minorIsPassport,
                        'parentIsPassport': widget.parentIsPassport,
                      });
                    }),
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
