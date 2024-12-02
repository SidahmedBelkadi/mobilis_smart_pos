import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/toast_helper.dart';
import 'package:mobilis_smart_pos/src/core/utils/ressources/app_colors.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/generate_contract_params_entity.dart';
import 'package:mobilis_smart_pos/src/features/contract/presentation/cubit/contract_cubit.dart';
import 'package:mobilis_smart_pos/src/features/contract/presentation/signature_screen.dart';
import 'package:mobilis_smart_pos/src/features/invoices/presentation/cubit/invoices_cubit.dart';
import 'package:mobilis_smart_pos/src/features/invoices/presentation/cubit/retry_activation/retry_activation_cubit.dart';
import 'package:mobilis_smart_pos/src/features/sign_in/data/data_sources/smart_pos_local_storage.dart';
import '../../../../core/utils/enums/invoice_status.dart';
import 'invoice_status.dart';

import '../../../../core/utils/helpers/app_localization_helper.dart';
import '../../../../core/utils/helpers/media_query_values.dart';
import '../../domain/entities/invoice_entity.dart';
import '../../../../dependency_injection/injection_container.dart' as di;

class Invoice extends StatelessWidget {
  const Invoice({
    super.key,
    required this.invoiceEntity,
  });

  final InvoiceEntity invoiceEntity;

  InvoiceStatusEnum _filterInvoiceStatus(String status, String? msisdn) {
    if (status.toLowerCase() == "dsa timeout" && msisdn == null) {
      return InvoiceStatusEnum.failed;
    } else if (status.toLowerCase() == "network_failure_treated" && msisdn == null) {
      return InvoiceStatusEnum.failed;
    } else if (status.toLowerCase() == "dsa Retrieval" && msisdn != null) {
      return InvoiceStatusEnum.success;
    } else if (status.toLowerCase() == "success" && msisdn != null) {
      return InvoiceStatusEnum.success;
    } else if (status.toLowerCase() == "pending" && msisdn == null) {
      return InvoiceStatusEnum.pending;
    } else {
      return InvoiceStatusEnum.failed;
    }
  }

  String _filterICCD(String iccd) {
    if (iccd.contains("_")) {
      return iccd.substring(iccd.indexOf("_") + 1);
    } else {
      return iccd;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.sp),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(
          Radius.circular(12.sp),
        ),
        border: Border.all(color: const Color.fromARGB(255, 207, 218, 199)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InvoiceStatus(
                      invoiceStatus:
                          _filterInvoiceStatus(invoiceEntity.status, invoiceEntity.msisdn),
                    ),
                    Text(
                      context.isArabicLocale
                          ? invoiceEntity.formattedInvoiceDateInArabic
                          : invoiceEntity.formattedInvoiceDate,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
                SizedBox(height: 16.sp),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "contractLabel".tr(context),
                      textAlign: TextAlign.start,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    Flexible(
                      child: Text(
                        invoiceEntity.contractCode,
                        style: Theme.of(context).textTheme.labelMedium!.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.sp),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "msisdn".tr(context),
                      textAlign: TextAlign.start,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    Flexible(
                      child: Text(
                        invoiceEntity.msisdn == null
                            ? "notAvailable".tr(context)
                            : invoiceEntity.msisdn.toString(),
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.sp),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "iccid".tr(context),
                            textAlign: TextAlign.start,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          Flexible(
                            child: Text(
                              invoiceEntity.iccid == null
                                  ? "notAvailable".tr(context)
                                  : _filterICCD(invoiceEntity.iccid.toString()),
                              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          )
                        ],
                      ),
                    ),
                    SizedBox(width: 12.sp),
                    _filterInvoiceStatus(invoiceEntity.status, invoiceEntity.msisdn) ==
                            InvoiceStatusEnum.pending
                        ? RetryActivationWidget(
                            invoiceEntity: invoiceEntity,
                          )
                        : const SizedBox.shrink()
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RetryActivationWidget extends StatefulWidget {
  const RetryActivationWidget({
    super.key,
    required this.invoiceEntity,
  });

  final InvoiceEntity invoiceEntity;

  @override
  State<RetryActivationWidget> createState() => _RetryActivationWidgetState();
}

class _RetryActivationWidgetState extends State<RetryActivationWidget> {
  String _smsMessage = "No message received yet.";
  bool smsLoading = false;
  late GenerateContractParamsEntity generateContractParamsEntity;
  String senderPhoneNumber =
      "+${di.serviceLocator<SmartPosLocalStorage>().getSavedLoginCredentials()!.msisdn!}";
  Timer? _smsTimer;

  static const platform = MethodChannel('sms/sms_receiver');

  Future<void> setSenderPhoneNumber(String number) async {
    try {
      await platform.invokeMethod('setSenderPhoneNumber', {'senderPhoneNumber': number});
    } on PlatformException catch (e) {
      debugPrint("Failed to set sender phone number: '${e.message}'.");
    }
  }

  Future<void> sendSms(String message, String recipient) async {
    try {
      setState(() {
        smsLoading = true;
      });
      await platform.invokeMethod('sendSms', {
        'message': message,
        'recipient': recipient,
        'dealerNumber': senderPhoneNumber,
      });
      debugPrint("=========== SMS SENT ===============");

      // Start the timer after SMS is sent
      _smsTimer = Timer(const Duration(seconds: 30), () {
        debugPrint("==================== TIMER FOR SMS STARTED");
        // AppToasts.showWarningToast(message: "DSA Timeout", context: context);
        generateContractParamsEntity.msisdn = "";
        context
            .read<ContractCubit>()
            .attributeMsisdnAndGenerateContract(params: generateContractParamsEntity);
      });
    } on PlatformException catch (e) {
      debugPrint("${e.message} ");
    }
  }

  void checkSmsSuccess(String message, BuildContext context) {
    debugPrint("==================== MESSAGE : $message");
    setState(() {
      generateContractParamsEntity.dsaMessage = message;
    });

    final RegExp regExp = RegExp(r'La carte SIM (\d+) est activee, avec le numero (2136\d{8})');
    final RegExp regExp2 = RegExp(r'Activation en cours');
    final match = regExp.firstMatch(message);
    final cubit = context.read<ContractCubit>();

    if (match != null) {
      final phoneNumber = match.group(2);
      debugPrint("==================== Success Message: $message");
      debugPrint("==================== Extracted Phone Number : $phoneNumber");
      if (phoneNumber != null) {
        generateContractParamsEntity.msisdn = phoneNumber;
        cubit.attributeMsisdnAndGenerateContract(params: generateContractParamsEntity);
      }
    } else {
      debugPrint("===================== Message: $message");
      if (!regExp2.hasMatch(message)) {
        generateContractParamsEntity.msisdn = "FAILED";
        cubit.attributeMsisdnAndGenerateContract(params: generateContractParamsEntity);
      } else if (regExp2.hasMatch(message)) {
      } else {
        AppToasts.showErrorToast(message: message, context: context);
      }
    }
  }

  @override
  void initState() {
    super.initState();

    platform.setMethodCallHandler((call) async {
      if (call.method == "receivedSms") {
        // Cancel the timer when SMS is received
        _smsTimer?.cancel();
        debugPrint("=================== TIMER FOR SMS STOPPED");

        setState(() {
          smsLoading = false;
          _smsMessage = call.arguments;
          checkSmsSuccess(_smsMessage, context);
        });
      }
    });

    // Set the sender's phone number
    setSenderPhoneNumber(senderPhoneNumber);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RetryActivationCubit, RetryActivationState>(
      builder: (context, state) {
        if ((state is RetryActivationLoading && state.id == widget.invoiceEntity.id) ||
            smsLoading) {
          return Container(
            padding: EdgeInsets.all(5.sp),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.all(Radius.circular(12.sp)),
            ),
            child: SizedBox(
              height: 16.sp,
              width: 16.sp,
              child: const CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          );
        }

        return GestureDetector(
          onTap: () {
            context
                .read<RetryActivationCubit>()
                .retryActivation(id: widget.invoiceEntity.id.toString());
          },
          child: Container(
            padding: EdgeInsets.all(5.sp),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.all(Radius.circular(12.sp)),
            ),
            child: Icon(
              FontAwesomeIcons.repeat,
              size: 16.sp,
              color: Colors.white,
            ),
          ),
        );
      },
      listener: (BuildContext context, RetryActivationState state) {
        if (state is RetryActivationSuccess) {
          final url = state.responseEntity.generateContractUrl;
          final sms = state.responseEntity.formattedStringSms;

          final List<String> parts = url.split('/');

          // Assign each part to a variable
          final int clientId = int.parse(parts[0]);
          final int invoiceId = int.parse(parts[1]);
          final int subscriptionId = int.parse(parts[2]);

          setState(() {
            generateContractParamsEntity = GenerateContractParamsEntity(
              clientId: clientId,
              invoiceId: invoiceId,
              subsId: subscriptionId,
              contractCode: widget.invoiceEntity.contractCode,
              dsaMessage: dsaMessage,
            );
          });

          sendSms(sms, "444");
        }
        // TODO : Don't forget to refresh list in case of Error of generation because the invoice will be deleted
        if (state is GenerateContractSuccess || state is GenerateContractFailed) {
          context.read<InvoicesCubit>().getInvoices(isFirstTime: true);
        }
      },
    );
  }
}
