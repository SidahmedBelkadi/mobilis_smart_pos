import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/session_timeout.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/end_points.dart';
import '../../../core/utils/helpers/app_localization_helper.dart';
import '../../../core/utils/helpers/media_query_values.dart';
import '../../../core/utils/ressources/app_colors.dart';
import '../../../core/utils/ressources/app_images.dart';
import '../../../dependency_injection/injection_container.dart' as di;
import '../../../services/upgrader_service.dart';
import '../../contract/presentation/choose_card_option_screen.dart';
import '../../forgot_password/presentation/cubit/forgot_password_cubit.dart';
import '../../home/presentation/home_screen.dart';
import '../../profile/presentation/cubit/profile_cubit.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../sign_in/data/data_sources/smart_pos_local_storage.dart';
import 'widgets/bottom_nav.dart';
import 'widgets/drawer.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, this.index = 0, this.fromSignin});

  final int? index;
  final bool? fromSignin;

  @override
  State<MainScreen> createState() => _MyHomePageState();
}

List<Widget> screens = [
  const HomeScreen(),
  const ChooseCardOptionScreen(),
  MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) => di.serviceLocator<ForgotPasswordCubit>(),
      ),
      BlocProvider(
        create: (_) => di.serviceLocator<ProfileCubit>()..getPdvInfo(),
      ),
    ],
    child: ProfileScreen(
      authenticationLocalDataSource: di.serviceLocator(),
    ),
  ),
];

late int screenIndex;

class _MyHomePageState extends State<MainScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.index == null) {
      screenIndex = 0;
    } else {
      screenIndex = widget.index ?? 0;
    }
    if (widget.fromSignin == null) {
      checkForUpdate();
    }
  }

  Future<void> checkForUpdate() async {
    bool isUpdateAvailable = await di.serviceLocator<UpgraderService>().checkIfLastVersionUpdate();

    if (isUpdateAvailable) {
      _showUpdateDialog();
    } else if (di.serviceLocator<SmartPosLocalStorage>().isUpdatePending()) {
      _showUpdateDialog();
    }
  }

  void _showUpdateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: context.isDarkMode ? AppColors.darkerGrey : Colors.white,
            title: Text("update_available".tr(context)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('update_available_instruction'.tr(context)),
                LottieBuilder.asset(AppImages.uploading, height: 120.sp, width: 120.sp),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () async {
                  final updateUrl = Uri.parse(EndPoints.downloadApk);
                  if (await canLaunchUrl(updateUrl)) {
                    await launchUrl(updateUrl);
                    exit(0); // Exit the app after update is initiated
                  } else {
                    debugPrint("========= could not launch URL");
                  }
                },
                child: Text('update_now'.tr(context)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        drawer: const HomeDrawer(),
        bottomNavigationBar: CustomAppBottomNavBar(
          currentIndex: screenIndex,
          onTap: (index) => setState(
            () {
              screenIndex = index;
            },
          ),
        ),
        body: screens[screenIndex],
      ),
    );
  }
}
