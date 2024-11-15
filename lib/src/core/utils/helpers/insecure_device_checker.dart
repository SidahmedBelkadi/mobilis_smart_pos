import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

import '../ressources/app_images.dart';

class InsecureDevice extends StatefulWidget {
  const InsecureDevice({super.key});

  @override
  _InsecureDeviceState createState() => _InsecureDeviceState();
}

class _InsecureDeviceState extends State<InsecureDevice> {
  int _remainingTime = 5; // 5 seconds countdown

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      setState(() {
        if (_remainingTime > 1) {
          _remainingTime--;
        } else {
          timer.cancel();
          _closeApp();
        }
      });
    });
  }

  void _closeApp() {
    exit(0);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.red,
            systemOverlayStyle:
                const SystemUiOverlayStyle(statusBarColor: Colors.red),
          ),
          backgroundColor: Colors.red,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Insecure Device",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                LottieBuilder.asset(
                  AppImages.securityShield,
                  width: 200,
                  height: 200,
                ),
                const SizedBox(height: 16),
                Text(
                  'Closing in $_remainingTime seconds...',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
