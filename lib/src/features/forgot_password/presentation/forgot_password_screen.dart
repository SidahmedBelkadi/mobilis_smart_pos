import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';

import '../../../config/routing/app_routes.dart';
import '../../../core/commom/widgets/app_text_form_field.dart';
import '../../../core/utils/enums/input_type.dart';
import '../../../core/utils/helpers/app_localization_helper.dart';
import '../../../core/utils/helpers/media_query_values.dart';
import '../../../core/utils/helpers/toast_helper.dart';
import '../../../core/utils/ressources/app_colors.dart';
import '../../../core/utils/ressources/app_images.dart';
import '../domain/entities/reset_password_request_otp_params.dart';
import 'cubit/forgot_password_cubit.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key, this.msisdn});

  final String? msisdn;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ForgotPasswordCubit>();
    return SafeArea(
      child: Scaffold(
        floatingActionButtonLocation: context.isArabicLocale
            ? FloatingActionButtonLocation.startFloat
            : FloatingActionButtonLocation.endFloat,
        floatingActionButton: BlocConsumer<ForgotPasswordCubit, ForgotPasswordState>(
          listener: (context, state) {
            if (state is ResetPasswordOTPFailure) {
              AppToasts.showErrorToast(
                message: state.message.tr(context),
                context: context,
              );
            }
            if (state is ResetPasswordOTPSuccess) {
              AppToasts.showSuccessToast(
                message: "code_has_been_sent".tr(context),
                context: context,
              );
              Navigator.of(context).pushNamed(Routes.forgotPasswordOTP,
                  arguments: {'msisdn': cubit.phoneController.text.trim()});
            }
          },
          builder: (context, state) {
            if (state is ResetPasswordOTPLoading) {
              return SizedBox(
                height: 32.sp,
                width: 32.sp,
                child: const CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              );
            }
            return FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: () => _onFABPressed(context, cubit),
              child:  FaIcon(
                FontAwesomeIcons.arrowRight, color : context.isDarkMode ? Colors.black : Colors.white ,
              ),
            );
          },
        ),
        body: SingleChildScrollView(
          child: Container(
            height: context.height,
            width: context.width,
            padding: EdgeInsets.all(24.sp),
            child: Column(
              children: [
                LottieBuilder.asset(
                  AppImages.phone1,
                  height: 300.h,
                  width: 300.w,
                ),
                if (msisdn == null)
                Text(
                  "phoneNumber".tr(context),
                  textAlign: TextAlign.center,
                  style:
                      Theme.of(context).textTheme.headlineSmall!.copyWith(color: AppColors.primary),
                ),
                SizedBox(height: 64.h),
                Form(
                  key: cubit.formKey,
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: msisdn != null ?
                    AppTextFormField(
                      enabled: false,
                      disabledValue: msisdn?.replaceFirst("213", "") ,
                      label: "msisdnLabel".tr(context),
                      prefixText: "(+213 🇩🇿)  ",
                      keyboardType: TextInputType.phone,
                      suffixIcon: Icons.phone_android,
                      textEditingController: cubit.phoneController,
                    ):
                    AppTextFormField(
                      enabled: msisdn == null,
                      disabledValue: msisdn?.replaceFirst("213", "") ,
                      label: "msisdnLabel".tr(context),
                      prefixText: "(+213 🇩🇿)  ",
                      validationType: InputType.PHONE,
                      keyboardType: TextInputType.phone,
                      suffixIcon: Icons.phone_android,
                      textEditingController: cubit.phoneController,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _onFABPressed(BuildContext context, ForgotPasswordCubit cubit) {
    final String phone = "213${cubit.phoneController.text.trim().replaceAll(' ', '')}";
    // final String phone = cubit.phoneController.text.trim();
    final params = ResetPasswordRequestOtpParams(msisdn: phone);
    cubit.resetPasswordRequestOTP(params: params);
  }
}
