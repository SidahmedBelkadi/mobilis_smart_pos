class SignInApproveContractParams {
  final String phone;
  final String refreshToken;
  final bool isConsent;

  SignInApproveContractParams({required this.phone, required this.refreshToken, required this.isConsent});

  Map<String, dynamic> toJson() {
    return {'msisdn': phone,'refresh_token': refreshToken ,'is_consent': isConsent};
  }
}
