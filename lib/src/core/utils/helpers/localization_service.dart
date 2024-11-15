import 'package:flutter/material.dart';

import 'app_localization_helper.dart';

class LocalizationService {
  final BuildContext context;

  LocalizationService(this.context);

  String getTranslation(String key) {
    return key.tr(context);
  }
}
