import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../../sign_in/data/data_sources/smart_pos_local_storage.dart';
import '../../domain/entities/reset_password_params.dart';
import '../../domain/entities/reset_password_request_otp_params.dart';
import '../../domain/use_cases/reset_password_otp_use_case.dart';
import '../../domain/use_cases/reset_password_use_case.dart';

part 'forgot_password_state.dart';

class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  final ResetPasswordOTPUseCase otpUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;
  final SmartPosLocalStorage authenticationLocalDataSource;

  ForgotPasswordCubit({
    required this.otpUseCase,
    required this.resetPasswordUseCase,
    required this.authenticationLocalDataSource,
  }) : super(ForgotPasswordInitial());

  GlobalKey<FormState> formKey = GlobalKey();
  GlobalKey<FormState> formKey2 = GlobalKey();
  TextEditingController phoneController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool isObsecure = true;

  void onObsecureClicked() {
    isObsecure = !isObsecure;
    emit(ObsecureClicked(isObsecure: isObsecure));
  }

  Future<void> resetPasswordRequestOTP({
    required ResetPasswordRequestOtpParams params,
    isProfile = false,
  }) async {
    if (!isProfile) {
      final isValidated = formKey.currentState!.validate();
      if (!isValidated) {
        return;
      }
    }

    emit(ResetPasswordOTPLoading());

    final failureOrMessage = await otpUseCase.resetPasswordOTP(params: params);

    failureOrMessage.fold(
      (error) {
        emit(ResetPasswordOTPFailure(message: error.message));
      },
      (message) {
        emit(ResetPasswordOTPSuccess(message: message));
      },
    );
  }

  Future<void> resetPassword(
      {required ResetPasswordParams params, isProfile = false}) async {
    if (!isProfile) {
      final isValidated = formKey2.currentState!.validate();
      if (!isValidated) {
        return;
      }
    }

    emit(ResetPasswordLoading());

    final failureOrMessage = await resetPasswordUseCase(params: params);

    failureOrMessage.fold(
      (error) {
        emit(ResetPasswordFailure(message: error.message));
      },
      (message) async {
        emit(ResetPasswordSuccess(message: message));
        await authenticationLocalDataSource.clearLoginCredentials();
      },
    );
  }
}
