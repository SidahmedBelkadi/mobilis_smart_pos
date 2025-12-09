import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobilis_smart_pos/src/config/routing/app_routes.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/app_localization_helper.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/dsa_regexp_helper.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/media_query_values.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/toast_helper.dart';
import 'package:mobilis_smart_pos/src/core/utils/ressources/app_colors.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/generate_contract_params_entity.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/retry_trigger_sms_params_entity.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/retry_trigger_sms_response_entity.dart';
import 'package:mobilis_smart_pos/src/features/contract/presentation/cubit/contract_cubit.dart';
import 'package:mobilis_smart_pos/src/features/contract/presentation/cubit/sms_cubit.dart';
import 'package:mobilis_smart_pos/src/features/invoices/domain/entities/invoice_entity.dart';
import 'package:mobilis_smart_pos/src/features/invoices/presentation/cubit/invoices_cubit.dart';
import 'package:mobilis_smart_pos/src/features/sign_in/data/data_sources/smart_pos_local_storage.dart';
import '../../../../dependency_injection/injection_container.dart' as di;

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
        _smsTimer?.cancel();
        setState(() {
          _smsMessage = call.arguments;
          checkSmsSuccess(_smsMessage, context);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SmsCubit, SmsState>(
      listener: (context, state) {
        if (state is RetryTriggerSmsFailure) {
          Navigator.of(context).pushNamedAndRemoveUntil(Routes.main, (route) => false);
          return AppToasts.showWarningToast(
              message: "activation_failed".tr(context), context: context);
        }
      },
      builder: (context, state) {
        return BlocConsumer<ContractCubit, ContractState>(
          listener: (context, state) {
            if (state is GenerateContractFailed) {
              Navigator.of(context).pushNamedAndRemoveUntil(Routes.main, (route) => false);
              return AppToasts.showWarningToast(
                  message: "problem_generating_contract".tr(context), context: context);
            }
            if (state is GenerateContractSuccess) {
              _smsTimer?.cancel();
              context.read<InvoicesCubit>().getInvoices(isFirstTime: true);
            }
          },
          builder: (context, state) {
            // if (state is GenerateContractLoading ) {
            //   return const RetryActivationLoadingWidget();
            // }
            return _isLoading
                ? const RetryActivationLoadingWidget()
                : RepeatActivationWidget(
                    onTap: () => _onRepeatActivationButtonTap(),
                  );
          },
        );
      },
    );
  }

  _onRepeatActivationButtonTap() async {
    final bool isBlocked = di.serviceLocator<SmartPosLocalStorage>().isRetryBlocked();

    if (isBlocked) {
      AppToasts.showWarningToast(message: "wait_for_seconds".tr(context), context: context);
      return;
    }

    final smsParams = RetryTriggerSmsParamsEntity(
      id: widget.invoiceEntity.id,
      msisdnAPN: senderPhoneNumber,
    );
    setState(() {
      _isLoading = true;
    });
    context.read<SmsCubit>().retryTriggerSms(smsParams: smsParams);
    di.serviceLocator<SmartPosLocalStorage>().blockRetryActivationTemporarly(seconds: 120);
    _startSmsTimer();
  }

  _startSmsTimer() {
    _smsTimer = Timer(const Duration(seconds: 40), () {
      AppToasts.showWarningToast(message: "activation_failed".tr(context), context: context);
      Navigator.of(context).pushNamedAndRemoveUntil(Routes.main, (route) => false);
    });
  }

  void checkSmsSuccess(String message, BuildContext context) async {
    final matchSuccessfulActivation =
        DsaRegexpHelper.simActivationSuccessfullyRegExp.firstMatch(message);
    final matchAlreadyActivatedSIM = DsaRegexpHelper.simAlreadyActivatedRegExp.firstMatch(message);

    if (matchSuccessfulActivation != null) {
      final phoneNumber = matchSuccessfulActivation.group(2);
      await _generateContract(phoneNumber: phoneNumber!, dsaMessage: message);
    } else if (matchAlreadyActivatedSIM != null) {
      final phoneNumber = matchAlreadyActivatedSIM.group(1);
      await _generateContract(phoneNumber: phoneNumber!, dsaMessage: message);
    } else if (DsaRegexpHelper.activationInProgressRegExp.hasMatch(message)) {
    } else {
      await _generateContract(phoneNumber: "FAILED", dsaMessage: message);
    }
  }

  _generateContract({required String phoneNumber, required String dsaMessage}) async {
    final params = GenerateContractParamsEntity(
        clientId: widget.invoiceEntity.clientId,
        invoiceId: widget.invoiceEntity.id,
        subsId: widget.invoiceEntity.subId,
        contractCode: widget.invoiceEntity.contractCode,
        dsaMessage: dsaMessage,
        msisdn: phoneNumber);

    await context.read<ContractCubit>().attributeMsisdnAndGenerateContract(
        params: params, lang: context.isArabicLocale ? 'AR' : 'FR');
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
