import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobilis_smart_pos/src/config/routing/app_routes.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/session_timeout.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import '../../../core/utils/helpers/app_localization_helper.dart';
import '../../../core/utils/helpers/media_query_values.dart';
import '../../../core/utils/ressources/app_colors.dart';
import '../../../core/utils/helpers/localization_utils.dart';
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
  const MainScreen(
      {super.key,
      this.index = 0,
      this.fromSignin,
      this.hasToChangePassowrd = false,
      this.hasToChangePassowrdOptional = false,
      this.daysLeft});

  final int? index;
  final bool? fromSignin;
  final bool? hasToChangePassowrd;
  final bool? hasToChangePassowrdOptional;
  final int? daysLeft;

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

    _checkForPassowrdExpiryAlert();

    if (widget.index == null) {
      screenIndex = 0;
    } else {
      screenIndex = widget.index ?? 0;
    }
    if (widget.fromSignin == null) {
      checkForUpdate();
    }
  }

  _checkForPassowrdExpiryAlert() async {
    await Future.delayed(Duration(seconds: 2));
    if (widget.hasToChangePassowrd == true ||
        di.serviceLocator<SmartPosLocalStorage>().hasToChangePassword() ||
        widget.hasToChangePassowrdOptional == true) {
      QuickAlert.show(
          context: context,
          type: QuickAlertType.warning,
          title: widget.hasToChangePassowrdOptional == true
              ? "password_will_expire_soon".tr(context)
              : "password_expired".tr(context),
          text: widget.hasToChangePassowrdOptional == true
              ? "password_will_expire_instruction".tr(context).replaceFirst('{duration}',
                  LocalizationUtils.getLocalizedDuration(context, widget.daysLeft ?? 0))
              : "password_expired_instruction".tr(context),
          barrierDismissible: kDebugMode ? true : widget.hasToChangePassowrdOptional ?? false,
          barrierColor: Colors.black.withOpacity(.8),
          backgroundColor: context.isDarkMode ? AppColors.darkerGrey : Colors.white,
          textColor: context.isDarkMode ? Colors.white : Colors.black,
          titleColor: context.isDarkMode ? Colors.white : Colors.black,
          confirmBtnColor: AppColors.primary,
          confirmBtnText: "changeButtonLabel".tr(context),
          onConfirmBtnTap: () {
            Navigator.of(context).pushNamed(Routes.changePassword);
          });
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

  /// Blocking in-app update (download with progress, then Android installer).
  Future<void> _showUpdateDialog() async {
    if (!mounted) return;
    final packageInfo = await PackageInfo.fromPlatform();
    if (!mounted) return;
    Navigator.of(context).pushNamed(Routes.appUpdate, arguments: {
      'currentVersion': packageInfo.version,
      'newVersion': di.serviceLocator<SmartPosLocalStorage>().getCheckedUpdatedversion(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return SessionTimeout(
      child: PopScope(
        canPop: false,
        child: Scaffold(
          drawer: screenIndex == 1 ? null : const HomeDrawer(),
          bottomNavigationBar: SafeArea(
            child: CustomAppBottomNavBar(
              currentIndex: screenIndex,
              onTap: (index) => setState(
                () {
                  screenIndex = index;
                },
              ),
            ),
          ),
          body: screens[screenIndex],
        ),
      ),
    );
  }
}
