import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobilis_smart_pos/src/core/commom/widgets/version.dart';
import 'widgets/theme_switcher.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../config/routing/app_routes.dart';
import '../../../core/commom/loading_button.dart';
import '../../../core/commom/widgets/app_text_form_field.dart';
import '../../../core/utils/enums/input_type.dart';
import '../../../core/utils/enums/themes_enum.dart';
import '../../../core/utils/helpers/app_localization_helper.dart';
import '../../../core/utils/helpers/media_query_values.dart';
import '../../../core/utils/helpers/toast_helper.dart';
import '../../../core/utils/ressources/app_colors.dart';
import '../../../core/utils/ressources/app_images.dart';
import '../../main/presentation/cubits/cubit/locale_cubit.dart';
import '../../main/presentation/cubits/cubit/theme_cubit.dart';
import '../domain/entities/sign_in_request_params.dart';
import 'cubit/sign_in_cubit.dart';
import 'widgets/elevated_button.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final GlobalKey<FormState> formKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SignInCubit>();

    return PopScope(
      canPop: false,
      child: Scaffold(
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.sp),
            child: Image.asset(
              AppImages.mobilisWithYou,
              height: 50.sp,
              width: 50.sp,
            ),
          ),
        ),
        appBar: AppBar(
          backgroundColor: context.isDarkMode ? AppColors.darkGrey : Colors.white,
          actions: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.sp),
              child: BlocBuilder<ThemeCubit, ChangeThemeState>(
                builder: (context, state) {
                  return ThemeSwitcher(
                    selectedTheme: state.theme,
                    onThemeChanged: (value) {
                      context.read<ThemeCubit>().changeTheme(value == AppThemes.darkTheme.name
                          ? AppThemes.darkTheme
                          : AppThemes.lightTheme);
                    },
                  );
                },
              ),
            )
          ],
          leading: BlocConsumer<LocaleCubit, ChangeLocalState>(
            listener: (context, state) {},
            builder: (context, state) {
              return PopupMenuButton<String>(
                icon: FaIcon(FontAwesomeIcons.language, color: AppColors.primary),
                onSelected: (value) {
                  context
                      .read<LocaleCubit>()
                      .changeLocale(languageCode: value.toString().toLowerCase().trim());
                },
                itemBuilder: (BuildContext context) {
                  return [
                    PopupMenuItem<String>(
                      value: 'ar',
                      child: Text("ar".tr(context)),
                    ),
                    PopupMenuItem<String>(
                      value: 'en',
                      child: Text("en".tr(context)),
                    ),
                    PopupMenuItem<String>(
                      value: 'fr',
                      child: Text("fr".tr(context)),
                    ),
                  ];
                },
              );
            },
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: SizedBox(
              height: context.height,
              width: context.width,
              child: Padding(
                padding: EdgeInsets.all(20.sp),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // MOBILIS LOGO IMAGE
                    Image.asset(
                      context.isDarkMode ? AppImages.msPosLogoVBlack : AppImages.msPosLogoV,
                      height: 200.h,
                      width: 200.w,
                    ),

                    SizedBox(height: 24.sp),

                    Text(
                      "signInTitle".tr(context),
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            color: AppColors.primary,
                          ),
                    ),

                    SizedBox(height: 32.sp),

                    // --- FROM + BUTTON
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // --- SIGNIN FORM

                        Form(
                          key: formKey,
                          child: Column(
                            children: [
                              // ---- MSISDN FIELD

                              Directionality(
                                textDirection: TextDirection.ltr,
                                child: AppTextFormField(
                                  label: "msisdnLabel".tr(context),
                                  prefixText: "(+213 🇩🇿)  ",
                                  validationType: InputType.PHONE,
                                  keyboardType: TextInputType.phone,
                                  suffixIcon: Icons.phone_android,
                                  textEditingController: cubit.phoneController,
                                ),
                              ),

                              SizedBox(height: 16.h),

                              // ---- PASSWORD FIELD
                              BlocBuilder<SignInCubit, SignInState>(
                                builder: (context, state) {
                                  return AppTextFormField(
                                    label: "password".tr(context),
                                    suffixIcon: cubit.isObsecure
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    isObsecure: cubit.isObsecure,
                                    onSuffixTap: () => cubit.onObsecureClicked(),
                                    textEditingController: cubit.passwordController,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        Align(
                          alignment:
                              context.isArabicLocale ? Alignment.centerLeft : Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.of(context)
                                .pushNamed(Routes.forgotPassword, arguments: {"msisdn": null}),
                            child: Text(
                              "forgotPassword".tr(context),
                              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ),

                        SizedBox(height: 24.h),

                        // --- SIGNIN BUTTON
                        BlocConsumer<SignInCubit, SignInState>(
                          listener: (context, state) {
                            if (state is SignInSuccessful) {
                              final isFirstLogin = state.signInResponseEntity.isFirstLogin;
                              if (isFirstLogin != null && isFirstLogin == true) {
                                AppToasts.showInfoToast(
                                  message: "USER_HAS_TO_CHANGE_DEFAULT_PASSWORD".tr(context),
                                  context: context,
                                  onAutoCompleteCompleted: (p0) {
                                    Navigator.of(context).pushNamed(Routes.forgotPassword,
                                        arguments: {"msisdn": cubit.phoneController.text});
                                  },
                                );
                              } else {
                                AppToasts.showSuccessToast(
                                  message: "code_has_been_sent".tr(context),
                                  context: context,
                                );
                                Navigator.of(context).pushNamed(Routes.otp, arguments: {
                                  'params': cubit.params,
                                  'responseParams': state.signInResponseEntity
                                });
                              }
                            } else if (state is SignInFailed) {
                              if (state.message == "USER_HAS_TO_CHANGE_DEFAULT_PASSWORD") {
                                AppToasts.showInfoToast(
                                  message: "USER_HAS_TO_CHANGE_DEFAULT_PASSWORD".tr(context),
                                  context: context,
                                  onAutoCompleteCompleted: (p0) {
                                    Navigator.of(context).pushNamed(Routes.forgotPassword,
                                        arguments: {"msisdn": cubit.phoneController.text});
                                  },
                                );
                              } else if (state.message.contains('REDIRECT_TO_CHANGE_PASSWORD')) {
                                AppToasts.showInfoToast(
                                  message: "USER_HAS_TO_CHANGE_PASSWORD".tr(context),
                                  context: context,
                                  onAutoCompleteCompleted: (p0) {
                                    Navigator.of(context).pushNamed(Routes.forgotPassword,
                                        arguments: {"msisdn": cubit.phoneController.text});
                                  },
                                );
                              } else {
                                AppToasts.showErrorToast(
                                  message: state.message.tr(context),
                                  context: context,
                                );
                              }
                            }
                          },
                          builder: (context, state) {
                            if (state is SignInLoading) {
                              return const LoadingButton();
                            }

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Button(
                                  cubit: cubit,
                                  formKey: formKey,
                                ),
                                SizedBox(height: 8.h),
                                const VersionWidget(),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Button extends StatelessWidget {
  const Button({super.key, required this.cubit, required this.formKey});

  final SignInCubit cubit;
  final GlobalKey<FormState> formKey;

  @override
  Widget build(BuildContext context) {
    return SignInElevatedButton(
      isDisabled: cubit.isDisabled,
      onPressed: () {
        _onSignInElevatedButtonPressed(cubit: cubit, formKey: formKey, context: context);
      },
      child: Text(
        "seConnecter".tr(context),
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.white),
      ),
    );
  }
}

Future<Position?> _determinePosition(BuildContext context) async {
  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    AppToasts.showErrorToast(
      message: "Location_services".tr(context),
      context: context,
    );
    return null;
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      AppToasts.showErrorToast(
        message: "PERMISSIONS_REQUIRED".tr(context),
        context: context,
      );
      return null;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    AppToasts.showErrorToast(
      message: "PERMISSIONS_REQUIRED".tr(context),
      context: context,
      onAutoCompleteCompleted: (p0) {
        openAppSettings();
      },
    );
    return null;
  }

  // When permissions are granted, get the position.
  return await Geolocator.getCurrentPosition();
}

void _onSignInElevatedButtonPressed(
    {required SignInCubit cubit,
    required GlobalKey<FormState> formKey,
    required BuildContext context}) async {
  cubit.disableButton();

  final isValidated = formKey.currentState!.validate();
  if (!isValidated) {
    cubit.enableButton();
    return;
  }

  final Position? position = await _determinePosition(context);
  if (position == null) {
    cubit.enableButton();
    return;
  }

  final String phone = "213${cubit.phoneController.text.trim().replaceAll(' ', '')}";

  final String password = cubit.passwordController.text.trim();

  SignInRequestParams params = SignInRequestParams(
    phone: phone,
    password: password,
  );
  cubit.params = params;
  cubit.signIn(params: params, context: context, position: position);
}
