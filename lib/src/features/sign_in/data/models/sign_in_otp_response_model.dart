import '../../domain/entities/sign_in_otp_response_entity.dart';

class SignInOTPResponseModel extends SignInOTPResponseEntity {
  const SignInOTPResponseModel({
    required super.accessToken,
    required super.refreshToken,
    required super.userIsConsent,
    required super.firstLogin,
    required super.passwordAge,
    super.userId,
    super.employeeId,
    super.msisdn,
    super.pdvCode,
    super.passwordValidityMonths,
  });

  factory SignInOTPResponseModel.fromJson(Map<String, dynamic> json) {
    return SignInOTPResponseModel(
        accessToken: json['access_token'] ?? '',
        refreshToken: json['refresh_token'] ?? '',
        userIsConsent: json['user_is_consent'],
        firstLogin: json['is_first_login'],
        //passwordAge: json['password_age'],
        passwordAge: '2025-10-21T00:00:00.000Z',
        userId: json['user_id'],
        employeeId: json['employee_id'],
        msisdn: json['msisdn'],
        pdvCode: json['pdv_code'],
        passwordValidityMonths: json['password_delay']);
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'user_is_consent': userIsConsent,
      'first_login': firstLogin,
      'password_age': passwordAge,
      'user_id': userId,
      'employee_id': employeeId,
      'msisdn': msisdn,
      'pdv_code': pdvCode,
    };
  }
}
