import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../helpers/app_localization_helper.dart';

const supportedLocales = [
  Locale('fr'),
  Locale('ar'),
  Locale('en'),
];

const localizationsDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

const langDropDrownEntries = ["fr", "ar", 'en'];
