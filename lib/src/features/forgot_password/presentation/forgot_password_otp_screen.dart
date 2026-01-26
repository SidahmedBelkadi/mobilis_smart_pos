import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import '../../sign_in/data/data_sources/smart_pos_local_storage.dart';
import '../../../services/notification_service.dart';

import '../../../config/routing/app_routes.dart';
import '../../../core/commom/widgets/app_elevated_button_text.dart';
import '../../../core/commom/widgets/app_text_form_field.dart';
import '../../../core/commom/widgets/otp_custom_widget.dart';
import '../../../core/utils/enums/input_type.dart';
import '../../../core/utils/helpers/app_localization_helper.dart';
import '../../../core/utils/helpers/media_query_values.dart';
import '../../../core/utils/helpers/toast_helper.dart';
import '../../../core/utils/ressources/app_colors.dart';
import '../../../core/utils/ressources/app_images.dart';
import '../../../dependency_injection/injection_container.dart' as di;
import '../domain/entities/reset_password_params.dart';
import 'cubit/forgot_password_cubit.dart';

class ForgotPasswordOtpScreen extends StatefulWidget {
  const ForgotPasswordOtpScreen({super.key, required this.msisdn});

  final String msisdn;

  @override
  State<ForgotPasswordOtpScreen> createState() => _ForgotPasswordOtpScreenState();
}

class _ForgotPasswordOtpScreenState extends State<ForgotPasswordOtpScreen> {
  static const MethodChannel otpChannel = MethodChannel('otp_receiver');
  String? receivedOtp;
  TextEditingController otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    setupOtpListener();
  }

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
  Widget build(BuildContext context) {
    final cubit = context.read<ForgotPasswordCubit>();

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          width: context.width,
          height: context.height,
          padding: EdgeInsets.all(32.sp),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ------ OTP Animation

              LottieBuilder.asset(
                AppImages.otp2,
                height: 170.h,
                width: 170.w,
              ),

              SizedBox(height: 96.h),

              // ---- OTP Paragraph
              Text(
                "otp".tr(context),
                textAlign: TextAlign.center,
                style:
                    Theme.of(context).textTheme.headlineSmall!.copyWith(color: AppColors.primary),
              ),

              SizedBox(height: 64.h),

              // --------- OTP Field & Logic

              BlocBuilder<ForgotPasswordCubit, ForgotPasswordState>(
                builder: (context, state) {
                  if (state is ResetPasswordLoading) {
                    return SizedBox(
                      height: 32.sp,
                      width: 32.sp,
                      child: const CircularProgressIndicator(),
                    );
                  }
                  return OTPCustomWidget(
                    controller: otpController,
                    onCompleted: (value) async {
                      await Future.delayed(const Duration(seconds: 1));
                      showModalBottomSheet(
                        isDismissible: false,
                        isScrollControlled: true,
                        enableDrag: false,
                        showDragHandle: true,
                        context: context,
                        builder: (context) {
                          return BlocProvider.value(
                            value: cubit,
                            child:
                                ForgotPasswordBottomSheet(otp: value.trim(), msisdn: widget.msisdn),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ForgotPasswordBottomSheet extends StatelessWidget {
  const ForgotPasswordBottomSheet({super.key, required this.otp, required this.msisdn});

  final String otp;
  final String msisdn;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ForgotPasswordCubit>();
    return SingleChildScrollView(
      child: Container(
        color: context.isDarkMode ? Colors.black : Colors.white,
        padding: EdgeInsets.only(
          right: 24.sp,
          left: 24.sp,
          bottom: MediaQuery.of(context).viewInsets.bottom + 32.sp,
          top: 64.sp,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "changePasswordSentence".tr(context),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  color: context.isDarkMode ? Colors.white : AppColors.categoryTextColorGrey),
            ),
            SizedBox(height: 32.sp),
            Form(
              key: cubit.formKey2,
              child: BlocBuilder<ForgotPasswordCubit, ForgotPasswordState>(
                builder: (context, state) {
                  return AppTextFormField(
                    label: "password".tr(context),
                    hint: "password".tr(context),
                    suffixIcon: cubit.isObsecure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    validationType: InputType.STRONG_PASSWORD,
                    isObsecure: cubit.isObsecure,
                    onSuffixTap: () => cubit.onObsecureClicked(),
                    textEditingController: cubit.passwordController,
                  );
                },
              ),
            ),
            SizedBox(height: 64.sp),
            BlocConsumer<ForgotPasswordCubit, ForgotPasswordState>(
              listener: (context, state) async {
                if (state is ResetPasswordFailure) {
                  AppToasts.showErrorToast(message: state.message.tr(context), context: context);
                  Navigator.of(context).pop();
                  cubit.passwordController.text = "";
                }
                if (state is ResetPasswordSuccess) {
                  AppToasts.showSuccessToast(
                    message: "password_updated".tr(context),
                    context: context,
                  );
                  await di.serviceLocator<SmartPosLocalStorage>().resetPasswordNotification();
                  Navigator.of(context).pushNamedAndRemoveUntil(Routes.signIn, (route) => false);
                }
              },
              builder: (context, state) {
                if (state is ResetPasswordLoading) {
                  return SizedBox(
                    height: 32.sp,
                    width: 32.sp,
                    child: const CircularProgressIndicator(),
                  );
                }
                return AppElevatedButtonWithText(
                  text: "confirm".tr(context),
                  onPressed: () {
                    final String newPassword = cubit.passwordController.text.trim();
                    final String phone = "213${msisdn.replaceAll(' ', '')}";

                    ResetPasswordParams params =
                        ResetPasswordParams(otp: otp, newPassword: newPassword, msisdn: phone);

                    cubit.resetPassword(params: params);
                  },
                );
              },
            ),
            SizedBox(height: 64.sp),
          ],
        ),
      ),
    );
  }
}
