import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:mobilis_smart_pos/src/services/pdf_cache_manager.dart';
import '../../../../core/utils/enums/themes_enum.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/utils/ressources/app_keys.dart';
import '../../domain/entities/sign_in_otp_response_entity.dart';

abstract class SmartPosLocalStorage {
  // =========== constent ========== //
  Future<void> setConsetment({required bool consent});
  bool isUserConsent();

  // =========== Sign in ========== //

  Future<void> saveLoginCredentials({required SignInOTPResponseEntity signInResponseEntity});

  SignInOTPResponseEntity? getSavedLoginCredentials();

  Future<void> clearLoginCredentials();

  // ========== Password Notifications ========== //

  Future<void> saveScheduledNotificationDate(DateTime dateTime);

  DateTime? getScheduledNotificationDate();

  Future<void> clearScheduledNotificationDate();

  // ============ Service maintenance ========= //
  /// Set when the service was suspended while logged in: the maintenance
  /// screen is shown again at the next launch until it has been read.
  bool isMaintenanceLogoutPending();

  Future<void> setMaintenanceLogoutPending(bool isPending);

  // ============ App Version update ========= //
  Future<void> saveCheckedUpdateDate(DateTime dateTime);

  Future<void> saveCheckedUpdateVersion(String version);

  DateTime? getCheckedUpdatedDate();

  String? getCheckedUpdatedversion();

  Future<void> clearCheckUpdateDate();

  bool isUpdatePending();

  void setUpdatePending(bool isPending);

  // ============= Theming =============== //
  saveTheme(AppThemes theme);

  AppThemes getCurrentTheme();

  // =========== SIM Slot Config =========== //

  Future<void> setPreferedSlot({required int slot});

  int? getPreferedSlot();

  // =========== Invoices retry Activation ========== //
  Future<void> blockRetryActivationTemporarly({required int seconds});

  void unBlockRetryActivationTemporarly();

  bool isRetryBlocked();

  // ========== Passsword Expiry ========= //

  Future<bool> shouldShowPasswordNotificationToday();
  Future<void> markPasswordNotificationAsShown();
  Future<void> resetPasswordNotification();
  Future<void> setHasToChangePassword();
  bool hasToChangePassword();
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

    // Clear PDF cache on logout
    await PdfCacheManager.clearCache();
    debugPrint('User logged out - all data cleared including PDF cache');
  }

  @override
  SignInOTPResponseEntity? getSavedLoginCredentials() {
    final String? accessToken = sharedPreferences.getString(AppKeys.accessToken);
    final String? refreshToken = sharedPreferences.getString(AppKeys.refreshToken);
    final int? userId = sharedPreferences.getInt(AppKeys.userId);
    final int? employee = sharedPreferences.getInt(AppKeys.employeeId);
    final String? msisdn = sharedPreferences.getString(AppKeys.msisdn);
    final String? pdvCode = sharedPreferences.getString(AppKeys.pdvCode);
    final String? businessName = sharedPreferences.getString(AppKeys.businessName);

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
  Future<void> saveLoginCredentials({required SignInOTPResponseEntity signInResponseEntity}) async {
    await sharedPreferences.setString(AppKeys.accessToken, signInResponseEntity.accessToken);
    await sharedPreferences.setString(AppKeys.refreshToken, signInResponseEntity.refreshToken);

    // Decode JWT token and log information
    Map<String, dynamic> decodedToken = JwtDecoder.decode(signInResponseEntity.accessToken);

    // Extract and save id, msisdn, and PDV_code if they exist
    final int? userId =
        decodedToken.containsKey('pdv_id') ? int.parse(decodedToken['pdv_id'].toString()) : null;

    final int? employeeId =
        decodedToken.containsKey('id') ? int.parse(decodedToken['id'].toString()) : null;
    final String? msisdn =
        decodedToken.containsKey('msisdn') ? decodedToken['msisdn'].toString() : null;
    final String? pdvCode =
        decodedToken.containsKey('PDV_code') ? decodedToken['PDV_code'].toString() : null;

    final String? businessName =
        decodedToken.containsKey('business_name') ? decodedToken['business_name'].toString() : null;

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
    await sharedPreferences.setString(AppKeys.scheduledNotification, dateTime.toIso8601String());
  }

  @override
  DateTime? getScheduledNotificationDate() {
    final String? dateString = sharedPreferences.getString(AppKeys.scheduledNotification);
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
    final String? dateString = sharedPreferences.getString(AppKeys.checkVerionUpdate);
    if (dateString != null) {
      final DateTime dateTime = DateTime.parse(dateString);
      return dateTime;
    }
    return null;
  }

  @override
  Future<void> saveCheckedUpdateDate(DateTime dateTime) async {
    debugPrint("========= DATE TO SAVE : ${dateTime.toIso8601String()}");
    await sharedPreferences.setString(AppKeys.checkVerionUpdate, dateTime.toIso8601String());
  }

  @override
  bool isMaintenanceLogoutPending() {
    return sharedPreferences.getBool(AppKeys.maintenanceLogout) ?? false;
  }

  @override
  Future<void> setMaintenanceLogoutPending(bool isPending) async {
    await sharedPreferences.setBool(AppKeys.maintenanceLogout, isPending);
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
    return storedThemeName == AppThemes.darkTheme.name ? AppThemes.darkTheme : AppThemes.lightTheme;
  }

  @override
  saveTheme(AppThemes theme) async {
    await sharedPreferences.setString(AppKeys.theme, theme.name);
  }

  @override
  String? getCheckedUpdatedversion() {
    final String? number = sharedPreferences.getString(AppKeys.checkVersionNumber);
    return number;
  }

  @override
  Future<void> saveCheckedUpdateVersion(String version) async {
    await sharedPreferences.setString(AppKeys.checkVersionNumber, version);
  }

  @override
  int? getPreferedSlot() {
    final int? number = sharedPreferences.getInt(AppKeys.slot);
    return number;
  }

  @override
  Future<void> setPreferedSlot({required int slot}) async {
    await sharedPreferences.setInt(AppKeys.slot, slot);
  }

  @override
  Future<void> blockRetryActivationTemporarly({required int seconds}) async {
    final DateTime now = DateTime.now();
    final DateTime blockUntil = now.add(Duration(seconds: seconds));
    await sharedPreferences.setString(AppKeys.blockRetryActivation, blockUntil.toIso8601String());
  }

  @override
  void unBlockRetryActivationTemporarly() async {
    await sharedPreferences.remove(AppKeys.blockRetryActivation);
  }

  @override
  bool isRetryBlocked() {
    final String? blockUntilString = sharedPreferences.getString(AppKeys.blockRetryActivation);
    debugPrint("==== result from local storage : $blockUntilString");
    if (blockUntilString == null) return false;

    final DateTime blockUntil = DateTime.parse(blockUntilString);
    return DateTime.now().isBefore(blockUntil);
  }

  @override
  bool isUserConsent() {
    return sharedPreferences.getBool(AppKeys.consent) ?? true;
  }

  @override
  Future<void> setConsetment({required bool consent}) async {
    await sharedPreferences.setBool(AppKeys.consent, consent);
  }

  // Key to store last shown date
  static const _lastPasswordNotificationKey = 'last_password_notification_date';
  // Key to store a flag to check if he has to change his password
  static const _hasToChangePassword = 'has_to_change_password';

// Returns true if notification has not been shown today, otherwise false
  @override
  Future<bool> shouldShowPasswordNotificationToday() async {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD
    final lastShownDate = sharedPreferences.getString(_lastPasswordNotificationKey);

    // If already shown today, do not show again
    return lastShownDate != todayStr;
  }

// Marks that a password notification has been shown today
  @override
  Future<void> markPasswordNotificationAsShown() async {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD
    await sharedPreferences.setString(_lastPasswordNotificationKey, todayStr);
  }

// Resets the daily notification (e.g., after password change)
  @override
  Future<void> resetPasswordNotification() async {
    debugPrint("======= NOTIFICATION RESET");
    await sharedPreferences.remove(_lastPasswordNotificationKey);
  }

  @override
  bool hasToChangePassword() {
    return sharedPreferences.getBool(_hasToChangePassword) ?? false;
  }

  @override
  Future<void> setHasToChangePassword() async {
    await sharedPreferences.setBool(_hasToChangePassword, true);
  }
}
