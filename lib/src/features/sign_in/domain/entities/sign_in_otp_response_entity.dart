import 'package:equatable/equatable.dart';
import 'package:mobilis_smart_pos/src/features/sign_in/domain/entities/password_age_entity.dart';

class SignInOTPResponseEntity extends Equatable {
  final String accessToken;
  final String refreshToken;
  final int? userId;
  final int? employeeId;
  final String? msisdn;
  final String? pdvCode;
  final bool? userIsConsent;
  final bool? firstLogin;
  final PasswordAge? passwordAge;
  final String? businessName;

  const SignInOTPResponseEntity(
      {required this.accessToken,
      required this.refreshToken,
      this.userIsConsent,
      this.firstLogin,
      this.userId,
      this.employeeId,
      this.msisdn,
      this.pdvCode,
      this.passwordAge,
      this.businessName});

  @override
  List<Object?> get props => [
        accessToken,
        refreshToken,
        userIsConsent,
        firstLogin,
        userId,
        msisdn,
        pdvCode,
        passwordAge,
        businessName
      ];

  @override
  String toString() {
    return 'SignInOTPResponseEntity(accessToken: $accessToken, refreshToken: $refreshToken, userIsConsent: $userIsConsent, firstLogin: $firstLogin, userId: $userId, msisdn: $msisdn, pdvCode: $pdvCode, passwordAge: $passwordAge)';
  }

  Map<String, dynamic> toMap() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'userIsConsent': userIsConsent,
      'firstLogin': firstLogin,
      'userId': userId,
      'employee': employeeId,
      'msisdn': msisdn,
      'pdvCode': pdvCode,
      'password_age': passwordAge?.toMap(),
    };
  }

  factory SignInOTPResponseEntity.fromMap(Map<String, dynamic> map) {
    return SignInOTPResponseEntity(
      accessToken: map['accessToken'] ?? '',
      refreshToken: map['refreshToken'] ?? '',
      userIsConsent: map['userIsConsent'],
      firstLogin: map['first_login'],
      userId: map['userId'],
      employeeId: map['employee'],
      msisdn: map['msisdn'],
      pdvCode: map['pdvCode'],
      passwordAge: map['password_age'] != null
          ? PasswordAge.fromMap(map['password_age'])
          : null,
    );
  }
}
