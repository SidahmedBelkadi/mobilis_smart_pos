import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:mobilis_smart_pos/src/config/routing/app_routes.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/session_timeout.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import '../../../core/api/end_points.dart';
import '../../../core/utils/helpers/app_localization_helper.dart';
import '../../../core/utils/helpers/media_query_values.dart';
import '../../../core/utils/ressources/app_colors.dart';
import '../../../core/utils/ressources/app_images.dart';
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
  static const platform = MethodChannel("channel");

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

  static Future<void> openInBrowser() async {
    try {
      await platform.invokeMethod('openBrowser', {'downloadUrl': EndPoints.downloadApk});
    } catch (e) {
      debugPrint('Error opening browser: $e');
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
                LottieBuilder.asset(AppImages.uploading, height: 120.sp, width: 120.sp),
                Text('update_available_instruction'.tr(context)),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: openInBrowser,
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
