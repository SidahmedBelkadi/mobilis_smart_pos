import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/insecure_device_checker.dart';

import 'src/core/security/device_security_config.dart';
import 'src/core/security/device_security_logger.dart';
import 'src/core/security/device_security_service.dart';
import 'src/core/utils/helpers/security_helper.dart';
import 'src/app.dart';
import 'src/dependency_injection/injection_container.dart' as di;

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Future.delayed(const Duration(milliseconds: 150));

  await di.initializeAppDependencies();
  await dotenv.load(fileName: ".env");

  // Enroll the device key in the background; signed requests wait for it.
  securityLog('Configuration : ${DeviceSecurityConfig.describe()}');
  if (DeviceSecurityConfig.enabled) {
    unawaited(di.serviceLocator<DeviceSecurityService>().ensureEnrolled());
  }

  final bool isNotSafeDevice = await SecurityCheck.checkSecurity();

  FlutterNativeSplash.remove();

  //await LocalNotificationService().init();

  // if (kDebugMode) {
  //   Bloc.observer = PrettyBlocObserver();
  // }

  if (isNotSafeDevice && !kDebugMode) {
    runApp(const InsecureDevice());
  } else {
    runApp(const SmartPos());
  }
}
