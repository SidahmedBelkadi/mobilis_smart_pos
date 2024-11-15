class SignInRequestParams {
  final String phone;
  final String password;
  final String? longitude;
  final String? latitude;

  SignInRequestParams({
    required this.phone,
    required this.password,
    this.longitude,
    this.latitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'msisdn': phone,
      'password': password,
      'longitude': longitude,
      'latitude': latitude
    };
  }

  SignInRequestParams copyWith({
    String? phone,
    String? password,
    String? longitude,
    String? latitude,
  }) {
    return SignInRequestParams(
      phone: phone ?? this.phone,
      password: password ?? this.password,
      longitude: longitude ?? this.longitude,
      latitude: latitude ?? this.latitude,
    );
  }
}
