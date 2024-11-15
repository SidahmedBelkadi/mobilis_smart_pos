// import 'package:flutter/material.dart';
// import 'package:mobilis_kyc/src/core/utils/helpers/encryption_helper.dart';
// import '../../../../core/utils/ressources/app_keys.dart';
// import '../../domain/entities/sign_in_otp_response_entity.dart';
// import '../../../sign_up/domain/entities/sign_up_response_entity.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:jwt_decoder/jwt_decoder.dart';
// import 'package:encrypt/encrypt.dart' as encrypt;

// abstract class AuthenticationLocalDataSource {
//   Future<void> saveLoginCredentials({required SignInOTPResponseEntity signInResponseEntity});
//   Future<void> saveRegisterCredentials({required SignUpResponseEnity signUpResponseEnity});
//   SignInOTPResponseEntity? getSavedLoginCredentials();
//   SignUpResponseEnity? getSavedRegisterCredentials();
//   Future<void> clearLoginCredentials();
// }

// class AuthenticationLocalDataSourceImpl implements AuthenticationLocalDataSource {
//   final SharedPreferences sharedPreferences;

//   AuthenticationLocalDataSourceImpl({required this.sharedPreferences});

//   @override
//   Future<void> clearLoginCredentials() async {
//     await sharedPreferences.remove(AppKeys.accessToken);
//     await sharedPreferences.remove(AppKeys.refreshToken);
//     await sharedPreferences.remove(AppKeys.userId);
//     await sharedPreferences.remove(AppKeys.employeeId);
//     await sharedPreferences.remove(AppKeys.msisdn);
//     await sharedPreferences.remove(AppKeys.pdvCode);
//   }

//   @override
//   SignInOTPResponseEntity? getSavedLoginCredentials() {
//     final String? encryptedAccessToken = sharedPreferences.getString(AppKeys.accessToken);
//     final String? encryptedRefreshToken = sharedPreferences.getString(AppKeys.refreshToken);
//     final int? userId = sharedPreferences.getInt(AppKeys.userId);
//     final int? employee = sharedPreferences.getInt(AppKeys.employeeId);
//     final String? msisdn = sharedPreferences.getString(AppKeys.msisdn);
//     final String? pdvCode = sharedPreferences.getString(AppKeys.pdvCode);

//     if (encryptedAccessToken != null && encryptedRefreshToken != null) {
//       try {
//         final accessToken = EncryptionHelper.decryptData(encryptedAccessToken);
//         final refreshToken = EncryptionHelper.decryptData(encryptedRefreshToken);
//         final signInResponseEntity = SignInOTPResponseEntity(
//           accessToken: accessToken,
//           refreshToken: refreshToken,
//           userId: userId,
//           employeeId: employee,
//           msisdn: msisdn,
//           pdvCode: pdvCode,
//         );
//         debugPrint('================ Retrieved credentials: \n'
//             'Access Token: ${signInResponseEntity.accessToken} \n'
//             'Refresh Token: ${signInResponseEntity.refreshToken} \n'
//             'PDV (USER) ID: ${signInResponseEntity.userId} \n'
//             'EMPLOYEE ID: ${signInResponseEntity.employeeId} \n'
//             'MSISDN: ${signInResponseEntity.msisdn} \n'
//             'PDV Code: ${signInResponseEntity.pdvCode}');

//         return signInResponseEntity;
//       } catch (e) {
//         debugPrint('Decryption error: $e');
//       }
//     }
//     return null;
//   }

//   @override
//   Future<void> saveLoginCredentials({required SignInOTPResponseEntity signInResponseEntity}) async {
//     try {
//       final encryptedAccessToken = EncryptionHelper.encryptData(signInResponseEntity.accessToken);
//       final encryptedRefreshToken = EncryptionHelper.encryptData(signInResponseEntity.refreshToken);

//       await sharedPreferences.setString(AppKeys.accessToken, encryptedAccessToken);
//       await sharedPreferences.setString(AppKeys.refreshToken, encryptedRefreshToken);

//       // Decode JWT token and log information
//       Map<String, dynamic> decodedToken = JwtDecoder.decode(signInResponseEntity.accessToken);
//       debugPrint('====================== Decoded JWT: $decodedToken');

//       // Extract and save id, msisdn, and PDV_code if they exist
//       final int? userId =
//           decodedToken.containsKey('pdv_id') ? int.parse(decodedToken['pdv_id'].toString()) : null;

//       final int? employeeId =
//           decodedToken.containsKey('id') ? int.parse(decodedToken['id'].toString()) : null;
//       final String? msisdn =
//           decodedToken.containsKey('msisdn') ? decodedToken['msisdn'].toString() : null;
//       final String? pdvCode =
//           decodedToken.containsKey('PDV_code') ? decodedToken['PDV_code'].toString() : null;

//       if (userId != null) {
//         await sharedPreferences.setInt(AppKeys.userId, userId);
//       }

//       if (employeeId != null) {
//         await sharedPreferences.setInt(AppKeys.employeeId, employeeId);
//       }
//       if (msisdn != null) {
//         await sharedPreferences.setString(AppKeys.msisdn, msisdn);
//       }
//       if (pdvCode != null) {
//         await sharedPreferences.setString(AppKeys.pdvCode, pdvCode);
//       }

//       debugPrint('====================== Saved credentials: $signInResponseEntity');
//     } catch (e) {
//       debugPrint('Encryption or saving error: $e');
//     }
//   }

//   @override
//   SignUpResponseEnity? getSavedRegisterCredentials() {
//     // Uncomment and update this section when you implement this method
//     // final int? pdv = sharedPreferences.getInt(AppKeys.pdv);
//     // final String? passCode = sharedPreferences.getString(AppKeys.pdvPassCode);
//     // final String? nif = sharedPreferences.getString(AppKeys.pdvNIF);
//     // final String? commercialRegister = sharedPreferences.getString(AppKeys.pdvCommercialRegister);
//     // final String? nin = sharedPreferences.getString(AppKeys.pdvNIN);

//     // if (pdv != null &&
//     //     passCode != null &&
//     //     nif != null &&
//     //     commercialRegister != null &&
//     //     nin != null) {
//     //   final signUpResponseEnity = SignUpResponseEnity(
//     //       pdv: pdv, passCode: passCode, nif: nif, commercialRegister: commercialRegister, nin: nin);
//     //   debugPrint('================ Retrieved credentials: $signUpResponseEnity');
//     //   return signUpResponseEnity;
//     // }
//     return null;
//   }

//   @override
//   Future<void> saveRegisterCredentials({required SignUpResponseEnity signUpResponseEnity}) async {
//     // Uncomment and update this section when you implement this method
//     // await sharedPreferences.setInt(AppKeys.pdv, signUpResponseEnity.pdv);
//     // await sharedPreferences.setString(AppKeys.pdvPassCode, signUpResponseEnity.passCode);
//     // await sharedPreferences.setString(AppKeys.pdvNIF, signUpResponseEnity.nif);
//     // await sharedPreferences.setString(
//     //     AppKeys.pdvCommercialRegister, signUpResponseEnity.commercialRegister);
//     // await sharedPreferences.setString(AppKeys.pdvNIN, signUpResponseEnity.nin);

//     debugPrint('====================== Saved credentials: $signUpResponseEnity');
//   }
// }

import 'package:flutter/cupertino.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:mobilis_smart_pos/src/core/utils/enums/themes_enum.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/utils/ressources/app_keys.dart';
import '../../domain/entities/sign_in_otp_response_entity.dart';

abstract class SmartPosLocalStorage {
  // =========== Sign in ========== //

  Future<void> saveLoginCredentials(
      {required SignInOTPResponseEntity signInResponseEntity});

  SignInOTPResponseEntity? getSavedLoginCredentials();

  Future<void> clearLoginCredentials();

  // ========== Password Notifications ========== //

  Future<void> saveScheduledNotificationDate(DateTime dateTime);

  DateTime? getScheduledNotificationDate();

  Future<void> clearScheduledNotificationDate();

  // ============ App Version update ========= //
  Future<void> saveCheckedUpdateDate(DateTime dateTime);

  DateTime? getCheckedUpdatedDate();

  Future<void> clearCheckUpdateDate();

  bool isUpdatePending();

  void setUpdatePending(bool isPending);

  // ============= Theming =============== //
  saveTheme(AppThemes theme);

  AppThemes getCurrentTheme();
}

class SmartPosLocalStorageImpl implements SmartPosLocalStorage {
  final SharedPreferences sharedPreferences;

  SmartPosLocalStorageImpl({required this.sharedPreferences});

  @override
  Future<void> clearLoginCredentials() async {
    await sharedPreferences.remove(AppKeys.accessToken);
    await sharedPreferences.remove(AppKeys.refreshToken);
    await sharedPreferences.remove(AppKeys.userId);
    await sharedPreferences.remove(AppKeys.employeeId);
    await sharedPreferences.remove(AppKeys.msisdn);
    await sharedPreferences.remove(AppKeys.pdvCode);
    await sharedPreferences.remove(AppKeys.businessName);
  }

  @override
  SignInOTPResponseEntity? getSavedLoginCredentials() {
    final String? accessToken =
        sharedPreferences.getString(AppKeys.accessToken);
    final String? refreshToken =
        sharedPreferences.getString(AppKeys.refreshToken);
    final int? userId = sharedPreferences.getInt(AppKeys.userId);
    final int? employee = sharedPreferences.getInt(AppKeys.employeeId);
    final String? msisdn = sharedPreferences.getString(AppKeys.msisdn);
    final String? pdvCode = sharedPreferences.getString(AppKeys.pdvCode);
    final String? businessName =
        sharedPreferences.getString(AppKeys.businessName);

    debugPrint("======== $accessToken");

    if (accessToken != null && refreshToken != null) {
      final signInResponseEntity = SignInOTPResponseEntity(
          accessToken: accessToken,
          refreshToken: refreshToken,
          userIsConsent: null,
          userId: userId,
          employeeId: employee,
          msisdn: msisdn,
          pdvCode: pdvCode,
          businessName: businessName);

      return signInResponseEntity;
    }
    return null;
  }

  @override
  Future<void> saveLoginCredentials(
      {required SignInOTPResponseEntity signInResponseEntity}) async {
    await sharedPreferences.setString(
        AppKeys.accessToken, signInResponseEntity.accessToken);
    await sharedPreferences.setString(
        AppKeys.refreshToken, signInResponseEntity.refreshToken);

    // Decode JWT token and log information
    Map<String, dynamic> decodedToken =
        JwtDecoder.decode(signInResponseEntity.accessToken);

    // Extract and save id, msisdn, and PDV_code if they exist
    final int? userId = decodedToken.containsKey('pdv_id')
        ? int.parse(decodedToken['pdv_id'].toString())
        : null;

    final int? employeeId = decodedToken.containsKey('id')
        ? int.parse(decodedToken['id'].toString())
        : null;
    final String? msisdn = decodedToken.containsKey('msisdn')
        ? decodedToken['msisdn'].toString()
        : null;
    final String? pdvCode = decodedToken.containsKey('PDV_code')
        ? decodedToken['PDV_code'].toString()
        : null;

    final String? businessName = decodedToken.containsKey('business_name')
        ? decodedToken['business_name'].toString()
        : null;

    if (userId != null) {
      await sharedPreferences.setInt(AppKeys.userId, userId);
    }

    if (employeeId != null) {
      await sharedPreferences.setInt(AppKeys.employeeId, employeeId);
    }
    if (msisdn != null) {
      await sharedPreferences.setString(AppKeys.msisdn, msisdn);
    }
    if (pdvCode != null) {
      await sharedPreferences.setString(AppKeys.pdvCode, pdvCode);
    }
    if (businessName != null) {
      await sharedPreferences.setString(AppKeys.businessName, businessName);
    }
  }

  @override
  Future<void> saveScheduledNotificationDate(DateTime dateTime) async {
    await sharedPreferences.setString(
        AppKeys.scheduledNotification, dateTime.toIso8601String());
  }

  @override
  DateTime? getScheduledNotificationDate() {
    final String? dateString =
        sharedPreferences.getString(AppKeys.scheduledNotification);
    if (dateString != null) {
      final DateTime dateTime = DateTime.parse(dateString);
      return dateTime;
    }
    return null;
  }

  @override
  Future<void> clearScheduledNotificationDate() async {
    await sharedPreferences.remove(AppKeys.scheduledNotification);
  }

  @override
  Future<void> clearCheckUpdateDate() async {
    await sharedPreferences.remove(AppKeys.checkVerionUpdate);
  }

  @override
  DateTime? getCheckedUpdatedDate() {
    final String? dateString =
        sharedPreferences.getString(AppKeys.checkVerionUpdate);
    if (dateString != null) {
      final DateTime dateTime = DateTime.parse(dateString);
      return dateTime;
    }
    return null;
  }

  @override
  Future<void> saveCheckedUpdateDate(DateTime dateTime) async {
    await sharedPreferences.setString(
        AppKeys.checkVerionUpdate, dateTime.toIso8601String());
  }

  @override
  bool isUpdatePending() {
    return sharedPreferences.getBool(AppKeys.isUpdatePening) ?? false;
  }

  @override
  void setUpdatePending(bool isPending) {
    sharedPreferences.setBool(AppKeys.isUpdatePening, isPending);
  }

  @override
  AppThemes getCurrentTheme() {
    final storedThemeName = sharedPreferences.getString(AppKeys.theme);
    return storedThemeName == AppThemes.darkTheme.name
        ? AppThemes.darkTheme
        : AppThemes.lightTheme;
  }

  @override
  saveTheme(AppThemes theme) async {
    await sharedPreferences.setString(AppKeys.theme, theme.name);
  }
}
