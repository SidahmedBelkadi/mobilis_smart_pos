class ResetPasswordParams {
  final String otp;
  final String newPassword;
  final String msisdn;

  ResetPasswordParams({required this.otp, required this.newPassword, required this.msisdn});

  Map<String, dynamic> toJson() {
    return {
      "otp": int.parse(otp),
      "newPassword": newPassword,
      "msisdn": msisdn,
    };
  }
}
