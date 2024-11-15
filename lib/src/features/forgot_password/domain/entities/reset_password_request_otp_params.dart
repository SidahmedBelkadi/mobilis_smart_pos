class ResetPasswordRequestOtpParams {
  final String msisdn;

  ResetPasswordRequestOtpParams({required this.msisdn});

  Map<String, dynamic> toJson() {
    return {
      "msisdn": msisdn,
    };
  }
}
