import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobilis_smart_pos/src/features/sign_in/domain/entities/password_age_entity.dart';
import '../../data/data_sources/smart_pos_local_storage.dart';
import '../../domain/entities/sign_in_approve_contract_params.dart';
import '../../domain/entities/sign_in_otp_request_params.dart';
import '../../domain/entities/sign_in_otp_response_entity.dart';
import '../../domain/entities/sign_in_request_params.dart';
import '../../domain/entities/sign_in_response.dart';
import '../../domain/use_cases/approve_contract_use_case.dart';
import '../../domain/use_cases/sign_in_use_case.dart';
import '../../domain/use_cases/verify_otp_use_case.dart';

part 'sign_in_state.dart';

class SignInCubit extends Cubit<SignInState> {
  final SignInUseCase signInUseCase;
  final VerifyOtpUseCase verifyOtpUseCase;
  final ApproveContractUseCase approveContractUseCase;
  final SmartPosLocalStorage localDataSource;

  SignInCubit({
    required this.signInUseCase,
    required this.verifyOtpUseCase,
    required this.approveContractUseCase,
    required this.localDataSource,
  }) : super(SignInInitial());

  // ----------- VARIABLES ------------------ //
  TextEditingController passwordController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  bool isObsecure = true;
  bool isDisabled = false;
  late SignInRequestParams params;

  // -------------------- SIGNIN------------------ //
  Future<void> signIn(
      {required SignInRequestParams params,
      required BuildContext context,
      required Position position}) async {
    emit(SignInLoading());

    final failureOrSignInresponseEntity = await signInUseCase(
        params: params.copyWith(
      longitude: position.longitude.toString(),
      latitude: position.latitude.toString(),
    ));

    failureOrSignInresponseEntity.fold(
      (error) {
        emit(SignInFailed(message: error.message));
        enableButton();
      },
      (signInResponseEntity) async {
        emit(SignInSuccessful(signInResponseEntity: signInResponseEntity));
        enableButton();
      },
    );
  }

  // -------------------- HIDE & SHOW PASSWORD------------------ //
  void onObsecureClicked() {
    isObsecure = !isObsecure;
    emit(ObsecureClicked(isObsecure: isObsecure));
  }

  // -------------------- Enable & Disable PASSWORD------------------ //
  void disableButton() {
    isDisabled = true;
    emit(DisableButton(isDisabled: isDisabled));
  }

  void enableButton() {
    isDisabled = false;
    emit(DisableButton(isDisabled: isDisabled));
  }

  // ---------------- VERIFY OTP ------------------ //
  Future<void> verifyOTP({required SignInOTPRequestParams params}) async {
    emit(OTPLoading());

    final failureOrSignInOTPResponseEntity = await verifyOtpUseCase(params: params);

    failureOrSignInOTPResponseEntity.fold(
      (error) {
        emit(OTPFailed(message: error.message));
      },
      (signInOTPResponseEntity) async {
        await localDataSource.clearLoginCredentials();
        await localDataSource.saveLoginCredentials(signInResponseEntity: signInOTPResponseEntity);
        final PasswordAge? passwordAge = signInOTPResponseEntity.passwordAge;
        if (passwordAge != null) {
          //! For development purpose only
          emit(OTPSuccessful(
              signInOTPResponseEntity: signInOTPResponseEntity,
              passwordNotification: const PasswordExpiryNotification(
                  shouldShow: true,
                  message: "Your password will expire in 15 days. Please change it.")));

          // final now = DateTime.now();

          // final lastChangedDate = now
          //     .subtract(Duration(
          //       days: passwordAge.days,
          //       hours: passwordAge.hours,
          //       minutes: passwordAge.minutes,
          //       seconds: passwordAge.seconds,
          //     ))
          //     .subtract(
          //       Duration(days: passwordAge.months * 30),
          //     ) // still approximate
          //     // Todo : Ask backend dev to send DateTime
          //     //? : (since months vary in length (28–31 days))
          //     .subtract(Duration(days: passwordAge.years * 365));

          // final expiryDate = lastChangedDate.add(const Duration(days: 180));
          // final remainingDuration = expiryDate.difference(now);
          // final int remainingDays = remainingDuration.inDays;

          // final bool isWithin15Days = remainingDays <= 15;
          // final bool isWithinLastWeek = remainingDays <= 7;

          // final bool shouldShowPasswordExpiryNotification = isWithin15Days || isWithinLastWeek;

          // debugPrint("#### 🔐 Last password changed on: $lastChangedDate");
          // debugPrint("#### 📆 Expiry date: $expiryDate");
          // debugPrint("#### ⏳ Remaining days: $remainingDays");
          // debugPrint("#### 🔔 Show notification? $shouldShowPasswordExpiryNotification");
          // if (shouldShowPasswordExpiryNotification) {
          //   emit(
          //     OTPSuccessful(
          //       signInOTPResponseEntity: signInOTPResponseEntity,
          //       passwordNotification: PasswordExpiryNotification(
          //           shouldShow: true, message: "Your password will expire in $remainingDays days."),
          //     ),
          //   );
          // } else {
          //   emit(OTPSuccessful(signInOTPResponseEntity: signInOTPResponseEntity));
          // }
        } else {
          emit(OTPSuccessful(signInOTPResponseEntity: signInOTPResponseEntity));
        }
      },
    );
  }

  // ---------------- APPROVE THE CONTRACT ------------------ //
  Future<void> appoveContract({required SignInApproveContractParams params}) async {
    emit(ApproveContractLoading());

    final failureOrMessage = await approveContractUseCase(params: params);

    failureOrMessage.fold(
      (error) {
        emit(ApproveContractFailed(message: error.message));
      },
      (message) async {
        emit(ApproveContractSuccessful(message: message));
      },
    );
  }
}
