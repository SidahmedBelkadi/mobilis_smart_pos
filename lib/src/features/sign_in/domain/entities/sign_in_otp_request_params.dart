class SignInOTPRequestParams {
  final String msisdn;
  final int otp;

  SignInOTPRequestParams({required this.msisdn, required this.otp});

  Map<String, dynamic> toJson() {
    return {"msisdn": msisdn, "otp": otp};
  }
}
