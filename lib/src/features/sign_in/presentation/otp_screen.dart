import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import '../domain/entities/sign_in_response.dart';

import '../../../config/routing/app_routes.dart';
import '../../../core/commom/widgets/otp_custom_widget.dart';
import '../../../core/utils/helpers/app_localization_helper.dart';
import '../../../core/utils/helpers/media_query_values.dart';
import '../../../core/utils/helpers/toast_helper.dart';
import '../../../core/utils/ressources/app_colors.dart';
import '../../../core/utils/ressources/app_images.dart';
import '../domain/entities/sign_in_otp_request_params.dart';
import '../domain/entities/sign_in_request_params.dart';
import 'cubit/sign_in_cubit.dart';

class OTPScreen extends StatefulWidget {
  const OTPScreen({
    super.key,
    required this.signInParams,
    required this.responseParams,
  });

  final SignInRequestParams signInParams;
  final SignInResponseEntity responseParams;

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
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
    final cubit = context.read<SignInCubit>();

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          width: context.width,
          height: context.height,
          padding: EdgeInsets.all(32.sp),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // ------ OTP Animation

              LottieBuilder.asset(
                AppImages.otp1,
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
              BlocConsumer<SignInCubit, SignInState>(
                listener: (context, state) {
                  if (state is OTPSuccessful) {
                    final bool? isConsent = state.signInOTPResponseEntity.userIsConsent;
                    if (widget.responseParams.isFirstLogin != null &&
                        widget.responseParams.isFirstLogin == true) {
                      Navigator.of(context).pushNamed(
                        Routes.forgotPassword,
                        arguments: {
                          'msisdn': widget.signInParams.phone,
                        },
                      );
                      return;
                    }
                    if (isConsent != null && isConsent) {
                      Navigator.of(context).pushNamedAndRemoveUntil(Routes.main, (route) => false);
                      return;
                    } else {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                          Routes.pdvEngagements,
                          arguments: {
                            'phone': widget.signInParams.phone,
                            'refresh_token': state.signInOTPResponseEntity.refreshToken,
                          },
                          (route) => false);
                    }
                  }
                  if (state is OTPFailed) {
                    AppToasts.showErrorToast(
                      message: state.message.tr(context),
                      context: context,
                    );
                  }
                },
                builder: (context, state) {
                  if (state is OTPLoading) {
                    return const CircularProgressIndicator();
                  }

                  return OTPCustomWidget(
                    controller: otpController,
                    onCompleted: (value) async {
                      await Future.delayed(const Duration(seconds: 1));
                      SignInOTPRequestParams params = SignInOTPRequestParams(
                        msisdn: widget.signInParams.phone,
                        otp: int.parse(value),
                      );
                      cubit.verifyOTP(params: params);
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
