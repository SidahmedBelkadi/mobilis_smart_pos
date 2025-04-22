import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/commom/widgets/custom_app_bar.dart';
import '../../../sign_in/data/data_sources/smart_pos_local_storage.dart';

import '../../../../config/routing/app_routes.dart';
import '../../../../core/commom/widgets/app_text_form_field.dart';
import '../../../../core/commom/widgets/otp_custom_widget.dart';
import '../../../../core/utils/enums/input_type.dart';
import '../../../../core/utils/helpers/app_localization_helper.dart';
import '../../../../core/utils/helpers/media_query_values.dart';
import '../../../../core/utils/helpers/toast_helper.dart';
import '../../../../core/utils/ressources/app_colors.dart';
import '../../../../dependency_injection/injection_container.dart' as di;
import '../../../forgot_password/domain/entities/reset_password_params.dart';
import '../../../forgot_password/domain/entities/reset_password_request_otp_params.dart';
import '../../../forgot_password/presentation/cubit/forgot_password_cubit.dart';

class ProfilePasswordUpdateScreen extends StatefulWidget {
  const ProfilePasswordUpdateScreen({super.key});

  @override
  State<ProfilePasswordUpdateScreen> createState() => _ProfilePasswordUpdateState();
}

late TextEditingController passwordController;
late TextEditingController passwordConfirmationController;
late GlobalKey<FormState> _key;
bool isPasswordObsecure = true;
bool isPasswordConfirmationObsecure = true;
bool isOTPRequested = false;
late String msisdn;

class _ProfilePasswordUpdateState extends State<ProfilePasswordUpdateScreen> {
  static const MethodChannel otpChannel = MethodChannel('otp_receiver');
  String? receivedOtp;
  TextEditingController otpController = TextEditingController();

  void setupOtpListener() {
    otpChannel.setMethodCallHandler((MethodCall call) async {
      if (call.method == "otp_received") {
        setState(() {
          receivedOtp = call.arguments;
          if (receivedOtp != null) {
            otpController.text = receivedOtp!;
          }
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    setupOtpListener();
    passwordController = TextEditingController();
    passwordConfirmationController = TextEditingController();
    _key = GlobalKey();
  }

  @override
  void dispose() {
    super.dispose();
    passwordController.dispose();
    passwordConfirmationController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ForgotPasswordCubit>();
    return Scaffold(
      appBar: CustomAppBar(title: "change_password".tr(context)),
      body: SingleChildScrollView(
        child: Container(
          width: context.width,
          padding: EdgeInsets.symmetric(vertical: 48.sp, horizontal: 24.sp),
          alignment: Alignment.center,
          child: BlocConsumer<ForgotPasswordCubit, ForgotPasswordState>(
            listener: (context, state) {
              if (state is ResetPasswordOTPFailure) {
                AppToasts.showErrorToast(message: state.message.tr(context), context: context);
              }
              if (state is ResetPasswordOTPSuccess) {
                AppToasts.showSuccessToast(
                    message: "code_has_been_sent".tr(context), context: context);
                setState(() {
                  isOTPRequested = true;
                });
              }
              if (state is ResetPasswordFailure) {
                AppToasts.showErrorToast(message: state.message.tr(context), context: context);
              }
              if (state is ResetPasswordSuccess) {
                AppToasts.showSuccessToast(message: state.message.tr(context), context: context);
                /*   AppToasts.showSuccessToast(
                    message: "passwordChangeSuccess".tr(context),
                    context: context);*/
                Navigator.of(context).pushNamedAndRemoveUntil(Routes.signIn, (route) => false);
              }
            },
            builder: (context, state) {
              if (state is ResetPasswordLoading) {
                return Center(
                  child: SizedBox(
                    height: 32.sp,
                    width: 32.sp,
                    child: const CircularProgressIndicator(),
                  ),
                );
              }
              if (state is ResetPasswordOTPSuccess) {
                return Column(
                  children: [
                    SizedBox(height: 24.sp),
                    Text(
                      "enterOtpMessage".tr(context),
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 48.sp),
                    OTPCustomWidget(
                      controller: otpController,
                      onCompleted: (value) async {
                        await Future.delayed(const Duration(seconds: 1));

                        final params = ResetPasswordParams(
                            otp: value,
                            newPassword: passwordController.text.trim(),
                            msisdn: msisdn);
                        cubit.resetPassword(params: params, isProfile: true);
                      },
                    )
                  ],
                );
              }
              return Form(
                key: _key,
                child: Column(
                  children: [
                    Text(
                      "modifyPasswordTitle".tr(context),
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 32.sp),
                    AppTextFormField(
                      label: "newPasswordLabel".tr(context),
                      suffixIcon: isPasswordObsecure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      validationType: InputType.STRONG_PASSWORD,
                      isObsecure: isPasswordObsecure,
                      onSuffixTap: () => setState(() {
                        isPasswordObsecure = !isPasswordObsecure;
                      }),
                      textEditingController: passwordController,
                    ),
                    SizedBox(height: 24.sp),
                    AppTextFormField(
                      label: "confirmPasswordLabel".tr(context),
                      suffixIcon: isPasswordConfirmationObsecure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      isObsecure: isPasswordConfirmationObsecure,
                      onSuffixTap: () => setState(() {
                        isPasswordConfirmationObsecure = !isPasswordConfirmationObsecure;
                      }),
                      textEditingController: passwordConfirmationController,
                    ),
                    SizedBox(height: 24.sp),
                    state is ResetPasswordOTPLoading
                        ? SizedBox(
                            height: 32.sp,
                            width: 32.sp,
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          )
                        : ElevatedButton(
                            onPressed: () => _onElevatedButtonPressed(cubit),
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.sp, horizontal: 24.sp),
                              child: Text(
                                'changeButtonLabel'.tr(context),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  _onElevatedButtonPressed(ForgotPasswordCubit cubit) {
    final isValidated = _key.currentState!.validate();
    if (!isValidated) {
      return;
    }

    if (passwordController.text.trim() != passwordConfirmationController.text.trim()) {
      AppToasts.showWarningToast(message: "passwordMismatchError".tr(context), context: context);
      return;
    }
    final authenticationLocalDataSource = di.serviceLocator<SmartPosLocalStorage>();
    final savedCredentials = authenticationLocalDataSource.getSavedLoginCredentials();
    if (savedCredentials != null) {
      if (savedCredentials.msisdn != null) {
        setState(() {
          msisdn = savedCredentials.msisdn!;
        });
        final params = ResetPasswordRequestOtpParams(msisdn: msisdn);
        cubit.resetPasswordRequestOTP(params: params, isProfile: true);
      } else {
        AppToasts.showErrorToast(message: "internalErrorMessage".tr(context), context: context);
      }
    } else {
      AppToasts.showErrorToast(message: "internalErrorMessage".tr(context), context: context);
    }
  }
}
