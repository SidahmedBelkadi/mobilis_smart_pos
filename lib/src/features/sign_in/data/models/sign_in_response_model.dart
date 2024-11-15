import '../../domain/entities/sign_in_response.dart';

class SignInResponseModel extends SignInResponseEntity {
  const SignInResponseModel(
      {required super.message, required super.isFirstLogin});

  factory SignInResponseModel.fromJson(Map<String, dynamic> json) {
    return SignInResponseModel(
        message: json['message'], isFirstLogin: json['first_login']);
  }
}
