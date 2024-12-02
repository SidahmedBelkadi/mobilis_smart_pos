import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/app_localization_helper.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/toast_helper.dart';
import 'package:mobilis_smart_pos/src/features/contract/presentation/parent_contract_screen.dart';
import 'package:mobilis_smart_pos/src/features/sign_in/data/data_sources/smart_pos_local_storage.dart';
import '../../../dependency_injection/injection_container.dart' as di;

class TestSms extends StatefulWidget {
  const TestSms({super.key});

  @override
  State<TestSms> createState() => _TestSmsState();
}

class _TestSmsState extends State<TestSms> {
  static const platform = MethodChannel('sms/sms_receiver');
  bool smsLoading = false;
  String _smsMessage = "No message received yet.";
  String senderPhoneNumber =
      "+${di.serviceLocator<SmartPosLocalStorage>().getSavedLoginCredentials()!.msisdn!}";
  Timer? _smsTimer;

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
      final code = await platform.invokeMethod('sendSms', {
        'message': message,
        'recipient': recipient,
        'dealerNumber': senderPhoneNumber,
      });
      _smsTimer = Timer(const Duration(seconds: 30), () {
        debugPrint("==================== TIMER FOR SMS STARTED");
        debugPrint("============== Cases of timeout =====>  sms MSISDN will be sent as NULL");
      });
    } on PlatformException catch (e) {
      handleSmsError(e.code, context);
    }
  }

  void checkSmsSuccess(String message, BuildContext context) {
    debugPrint("==================== MESSAGE : $message");

    final RegExp regExp = RegExp(r'La carte SIM (\d+) est activee, avec le numero (2136\d{8})');
    final RegExp regExp2 = RegExp(r'Activation en cours');
    final match = regExp.firstMatch(message);

    if (match != null) {
      final phoneNumber = match.group(2);
      debugPrint("==================== Success Message: $message");
      debugPrint("==================== Extracted Phone Number : $phoneNumber");
      debugPrint(
          "========================= IN THIS CASE EVERY THING IS CORRECT AND MSISDN IS AVAILABLE");
    } else {
      debugPrint("===================== Message: $message");
      if (!regExp2.hasMatch(message)) {
        debugPrint("========================= ERROR MESSAGE FROM DSA SO 'FAILED' WILL BE SENT");
      } else if (regExp2.hasMatch(message)) {
      } else {
        AppToasts.showErrorToast(message: message, context: context);
        Navigator.of(context).pop();
      }
    }
  }

  void handleSmsError(String code, BuildContext context) {
    String errorMessage;
    switch (code) {
      case 'PERMISSION_DENIED':
        errorMessage = "PERMISSION_DENIED";
        break;
      case 'SIM_NOT_READY':
        errorMessage = "SIM_NOT_READY";
        break;
      case 'AIRPLANE_MODE':
        errorMessage = "AIRPLANE_MODE";
        break;
      case 'NO_SMS_NETWORK':
        errorMessage = "NO_SMS_NETWORK";
        break;
      case 'NO_SIM':
        errorMessage = "NO_SIM";
        break;
      case 'INVALID_OPERATOR':
        errorMessage = "INVALID_OPERATOR";
        break;
      case 'SMS_FAILED':
        errorMessage = "SMS_FAILED";
        break;
      default:
        errorMessage = "UNKNOWN_ERROR";
    }
    AppToasts.showErrorToast(message: errorMessage.tr(context), context: context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            sendSms("Hello", "444");
          },
          child: const Text("SMS"),
        ),
      ),
    );
  }
}
