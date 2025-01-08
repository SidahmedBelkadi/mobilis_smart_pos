import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobilis_smart_pos/src/config/routing/app_routes.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/toast_helper.dart';
import 'package:mobilis_smart_pos/src/core/utils/ressources/app_colors.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/generate_contract_params_entity.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/retry_trigger_sms_params_entity.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/retry_trigger_sms_response_entity.dart';
import 'package:mobilis_smart_pos/src/features/contract/presentation/cubit/contract_cubit.dart';
import 'package:mobilis_smart_pos/src/features/contract/presentation/cubit/sms_cubit.dart';
import 'package:mobilis_smart_pos/src/features/sign_in/data/data_sources/smart_pos_local_storage.dart';

import '../../../../core/utils/enums/invoice_status.dart';
import '../../../../core/utils/helpers/app_localization_helper.dart';
import '../../../../core/utils/helpers/media_query_values.dart';
import '../../../../dependency_injection/injection_container.dart' as di;
import '../../domain/entities/invoice_entity.dart';
import 'invoice_status.dart';

class Invoice extends StatelessWidget {
  const Invoice({
    super.key,
    required this.invoiceEntity,
  });

  final InvoiceEntity invoiceEntity;

  InvoiceStatusEnum _filterInvoiceStatus(String status, String? msisdn) {
    String normalizedStatus = status.toLowerCase();

    if (msisdn == null) {
      switch (normalizedStatus) {
        case 'dsa timeout':
        case 'network_failure_treated':
          return InvoiceStatusEnum.failed;
        case 'pending':
          return InvoiceStatusEnum.pending;
        default:
          return InvoiceStatusEnum.failed;
      }
    } else {
      switch (normalizedStatus) {
        case 'dsa retrieval':
        case 'success':
          return InvoiceStatusEnum.success;
        default:
          return InvoiceStatusEnum.success;
      }
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
  bool _isLoading = false;
  String _smsMessage = "No message received yet.";
  String dsaMessage = '';
  RetryTriggerSmsResponseEntity? retryTriggerSmsResponseEntity;

  late GenerateContractParamsEntity generateContractParamsEntity;
  String senderPhoneNumber =
      di.serviceLocator<SmartPosLocalStorage>().getSavedLoginCredentials()!.msisdn!;
  Timer? _smsTimer;

  static const platform = MethodChannel('sms/sms_receiver');

  @override
  void dispose() {
    _smsTimer?.cancel();
    super.dispose();
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
          _smsMessage = call.arguments;
          checkSmsSuccess(_smsMessage, context);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final smsCubit = context.read<SmsCubit>();

    return BlocConsumer<SmsCubit, SmsState>(
      listener: (context, state) {
        if (state is RetryTriggerSmsFailure) {
          setState(() {
            _isLoading = false;
          });
          AppToasts.showWarningToast(message: "activation_failed".tr(context), context: context);
          Navigator.of(context).pushNamedAndRemoveUntil(Routes.main, (route) => false);
        }
        if (state is RetryTriggerSmsSuccess) {
          setState(() {
            retryTriggerSmsResponseEntity = state.retryTriggerSmsResponseEntity;
          });
        }
      },
      builder: (context, state) {
        return BlocConsumer<ContractCubit, ContractState>(
          listener: (context, state) {
            if (state is GenerateContractFailed) {
              setState(() {
                _isLoading = false;
              });
              AppToasts.showWarningToast(
                  message: "problem_generating_contract".tr(context), context: context);
              Navigator.of(context).pushNamedAndRemoveUntil(Routes.main, (route) => false);
            }
            if (state is GenerateContractSuccess) {
              setState(() {
                _isLoading = false;
              });
              AppToasts.showSuccessToast(
                  message: "generated_success".tr(context), context: context);
              Navigator.of(context).pushNamedAndRemoveUntil(Routes.main, (route) => false);
            }
          },
          builder: (context, state) {
            if (state is GenerateContractLoading) {
              return const RetryActivationLoadingWidget();
            }
            return _isLoading
                ? const RetryActivationLoadingWidget()
                : RepeatActivationWidget(
                    onTap: () async {
                      final bool isBlocked =
                          di.serviceLocator<SmartPosLocalStorage>().isRetryBlocked();

                      if (isBlocked) {
                        AppToasts.showWarningToast(
                            message: "wait_for_seconds".tr(context), context: context);
                        return;
                      }

                      final smsParams = RetryTriggerSmsParamsEntity(
                        id: widget.invoiceEntity.id,
                        msisdnAPN: senderPhoneNumber,
                      );
                      setState(() {
                        _isLoading = true;
                      });
                      await smsCubit.retryTriggerSms(smsParams: smsParams);
                      // Block retries for 90 seconds
                      di
                          .serviceLocator<SmartPosLocalStorage>()
                          .blockRetryActivationTemporarly(seconds: 120);
                      _startSmsTimer();
                    },
                  );
          },
        );
      },
    );
  }

  _startSmsTimer() {
    _smsTimer = Timer(const Duration(seconds: 30), () {
      AppToasts.showWarningToast(message: "activation_failed".tr(context), context: context);
      Navigator.of(context).pushNamedAndRemoveUntil(Routes.main, (route) => false);
    });
  }

  _generateContract({required RetryTriggerSmsResponseEntity params, required String msisdn}) {
    if (retryTriggerSmsResponseEntity != null) {
      generateContractParamsEntity = GenerateContractParamsEntity(
          clientId: retryTriggerSmsResponseEntity!.clientId,
          invoiceId: retryTriggerSmsResponseEntity!.invoiceId,
          subsId: retryTriggerSmsResponseEntity!.subsId,
          contractCode: retryTriggerSmsResponseEntity!.contractCode,
          dsaMessage: dsaMessage,
          msisdn: msisdn);

      context
          .read<ContractCubit>()
          .attributeMsisdnAndGenerateContract(params: generateContractParamsEntity);
    }
    return;
  }

  void checkSmsSuccess(String message, BuildContext context) {
    setState(() {
      generateContractParamsEntity.dsaMessage = message;
    });

    // RegExp for the original cases
    final RegExp regExp = RegExp(r'La carte SIM (\d+) est activee, avec le numero (2136\d{8})');
    final RegExp regExp2 = RegExp(r'Activation en cours');

    // New RegExp for the "SIM deja active" case
    final RegExp regExp3 = RegExp(r'SIM deja active avec MSISDN (\d{12})');

    final match = regExp.firstMatch(message);

    if (match != null) {
      final phoneNumber = match.group(2);
      if (phoneNumber != null) {
        _generateContract(params: retryTriggerSmsResponseEntity!, msisdn: phoneNumber);
      }
    } else if (regExp3.hasMatch(message)) {
      final match3 = regExp3.firstMatch(message);
      final phoneNumber = match3?.group(1);
      if (phoneNumber != null) {
        _generateContract(params: retryTriggerSmsResponseEntity!, msisdn: phoneNumber);
      }
    } else {
      if (!regExp2.hasMatch(message)) {
        _generateContract(params: retryTriggerSmsResponseEntity!, msisdn: "FAILED");
      }
    }
  }
}

class RepeatActivationWidget extends StatelessWidget {
  const RepeatActivationWidget({
    super.key,
    this.onTap,
  });

  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
  }
}

class RetryActivationLoadingWidget extends StatelessWidget {
  const RetryActivationLoadingWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
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
}
