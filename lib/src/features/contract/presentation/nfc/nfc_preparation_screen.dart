import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/session_timeout.dart';

import '../../../../core/utils/ressources/app_colors.dart';
import '../../../../core/utils/ressources/app_images.dart';
import '../../../../core/utils/ressources/app_strings.dart';

class NfcPreparationScreen extends StatefulWidget {
  static const MethodChannel _channel = MethodChannel('com.example/my_channel');
  const NfcPreparationScreen({super.key});

  @override
  State<NfcPreparationScreen> createState() => _NfcPreparationScreenState();
}

class _NfcPreparationScreenState extends State<NfcPreparationScreen> {
  @override
  void initState() {
    super.initState();
    NfcPreparationScreen._channel.setMethodCallHandler((call) async {
      if (call.method == 'NFC') {
        // Map data = call.arguments;
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //       builder: (context) => SignUpScreenV1(
        //             data: data,
        //           )),
        // );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SessionTimeout(
      child: SafeArea(
        child: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(32.sp),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppStrings.nfcPreparationText,
                  style:
                      Theme.of(context).textTheme.headlineSmall!.copyWith(color: AppColors.primary),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32.sp),
                Lottie.asset(AppImages.nfcAnimation, height: 300.h, width: 350.w),
                SizedBox(height: 32.sp),
                ElevatedButton(
                    onPressed: () async {
                      await NfcPreparationScreen._channel.invokeMethod('NFC');
                    },
                    child: const Text("Start Scan")),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
