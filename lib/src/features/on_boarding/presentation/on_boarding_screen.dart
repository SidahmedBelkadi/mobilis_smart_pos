import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/commom/widgets/custom_floating_action_button.dart';
import 'package:typewritertext/typewritertext.dart';

import '../../../config/routing/app_routes.dart';
import '../../../core/utils/helpers/app_localization_helper.dart';
import '../../../core/utils/helpers/launch_helper.dart';
import '../../../core/utils/helpers/media_query_values.dart';
import '../../../core/utils/ressources/app_colors.dart';
import '../../../core/utils/ressources/app_images.dart';
import '../../../dependency_injection/injection_container.dart' as di;
import '../../main/presentation/cubits/cubit/locale_cubit.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({super.key});

  @override
  OnBoardingScreenState createState() => OnBoardingScreenState();
}

class OnBoardingScreenState extends State<OnBoardingScreen> {
  int _currentIndex = 0;
  bool _showFab = false;
  bool _showMobilisWithYou = false;
  late List<String> _texts;

  @override
  void initState() {
    super.initState();
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()!
        .requestNotificationsPermission();
    Timer(
      const Duration(seconds: 13),
      () {
        setState(() {
          _showMobilisWithYou = true;
        });
      },
    );
    Timer(const Duration(seconds: 15), () {
      setState(() {
        _showFab = true;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeTexts();
    _showNextText();
  }

  void _initializeTexts() {
    _texts = [
      "welcomeTitle".tr(context),
      "presentationTitle".tr(context),
      "welcomeParagraph".tr(context),
    ];
  }

  void _showNextText() async {
    while (_currentIndex < _texts.length) {
      await Future.delayed(const Duration(milliseconds: 3000));
      setState(() {
        _currentIndex++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String currentLangCode = Localizations.localeOf(context).languageCode;
    return BlocListener<LocaleCubit, ChangeLocalState>(
      listener: (context, state) {
        // Update the texts when the locale changes
        setState(() {
          _initializeTexts();
        });
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 32.sp),
              height: context.height,
              width: context.width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  if (_currentIndex > 0)
                    Image.asset(context.isDarkMode ? AppImages.msPosLogoBlack : AppImages.msPosLogo,
                        height: 250.sp, width: 250.sp),
                  TypeWriter.text(
                    _texts[0],
                    duration: const Duration(milliseconds: 50),
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall!
                        .copyWith(color: AppColors.primary, fontSize: 20.sp),
                  ),
                  SizedBox(height: 32.h),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (_currentIndex > 1)
                        TypeWriter.text(
                          _texts[1],
                          duration: const Duration(milliseconds: 20),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      SizedBox(height: 16.h),
                      if (_currentIndex > 2)
                        Padding(
                          padding: currentLangCode == 'ar'
                              ? EdgeInsets.only(right: 12.sp)
                              : EdgeInsets.only(left: 12.sp),
                          child: TypeWriter.text(
                            _texts[2],
                            duration: const Duration(milliseconds: 20),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      if (_showMobilisWithYou)
                        Center(
                          child: Image.asset(
                            AppImages.mobilisWithYou,
                            height: 100.sp,
                            width: 100.sp,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: _showFab
            ? CustomFAB(
                label: "continuer".tr(context),
                icon: CupertinoIcons.chevron_left,
                onPressed: () async {
                  di.serviceLocator<LaunchHelper>().firstTime();
                  Navigator.of(context).pushReplacementNamed(Routes.signIn);
                })
            : null,
      ),
    );
  }
}
