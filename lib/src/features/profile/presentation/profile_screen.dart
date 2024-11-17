import 'package:flutter/material.dart';
import '../../../core/commom/widgets/custom_app_bar.dart';

import '../../../core/utils/helpers/app_localization_helper.dart';
import '../../sign_in/data/data_sources/smart_pos_local_storage.dart';
import 'widget/personal_info.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.authenticationLocalDataSource,
  });

  final SmartPosLocalStorage authenticationLocalDataSource;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "profile_info".tr(context),
      ),
      body: const ProfilePersonalInformations(),
    );
  }
}
