import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'src/core/utils/helpers/insecure_device_checker.dart';
import 'src/core/utils/helpers/security_helper.dart';
import 'src/services/notification_service.dart';

import 'src/app.dart';
import 'src/dependency_injection/injection_container.dart' as di;

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Future.delayed(const Duration(milliseconds: 150));

  await di.initializeAppDependencies();
  await NotificationService.init();

  final bool isNotSafeDevice = await SecurityCheck.checkSecurity();

  FlutterNativeSplash.remove();

  if (isNotSafeDevice) {
    runApp(const InsecureDevice());
  } else {
    runApp(const SmartPos());
  }
}
