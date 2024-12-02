import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/toast_helper.dart';
import 'package:mobilis_smart_pos/src/features/contract/presentation/cubit/contract_cubit.dart';
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
        debugPrint("============== Cases of timeout =====>  sms MSISDN will be sent as NULL");
      });
    } on PlatformException catch (e) {
      debugPrint("${e.message} ");
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
