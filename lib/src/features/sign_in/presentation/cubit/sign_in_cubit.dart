import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/app_localization_helper.dart';
import 'package:mobilis_smart_pos/src/services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/utils/helpers/toast_helper.dart';
import '../../data/data_sources/smart_pos_local_storage.dart';
import '../../domain/entities/sign_in_approve_contract_params.dart';
import '../../domain/entities/sign_in_otp_request_params.dart';
import '../../domain/entities/sign_in_otp_response_entity.dart';
import '../../domain/entities/sign_in_request_params.dart';
import '../../domain/entities/sign_in_response.dart';
import '../../domain/use_cases/approve_contract_use_case.dart';
import '../../domain/use_cases/sign_in_use_case.dart';
import '../../domain/use_cases/verify_otp_use_case.dart';
import '../../../../dependency_injection/injection_container.dart' as di;

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
        emit(OTPSuccessful(signInOTPResponseEntity: signInOTPResponseEntity));
        //     final passwordAge = signInOTPResponseEntity.passwordAge;
        //     if (passwordAge != null) {
        //       // Calculate expiry and notification dates
        //       final expiryDate = NotificationService.calculateExpiryDate(passwordAge.toMap());
        //       final notificationDate = NotificationService.calculateNotificationDate(expiryDate);

        //       await NotificationService.cancelAll();

        //       // Schedule a new notification
        //       await NotificationService.schedulePasswordExpiryNotification(
        //         notificationDate,
        //         'Rappel',
        //         'Votre mot de passe expirera dans 15 jours. Veuillez le changer.',
        //       );

        //       // Save the new notification date
        //       await di
        //           .serviceLocator<SmartPosLocalStorage>()
        //           .saveScheduledNotificationDate(notificationDate);
        //     }
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
