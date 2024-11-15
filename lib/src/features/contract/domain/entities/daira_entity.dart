class Daira {
  final int id;
  final String code;
  final String stateCode;
  final String name;
  final String arName;

  Daira({
    required this.id,
    required this.code,
    required this.stateCode,
    required this.name,
    required this.arName,
  });

  factory Daira.fromJson(Map<String, dynamic> json) {
    return Daira(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      stateCode: json['state_code'] ?? '',
      name: json['name'] ?? '',
      arName: json['ar_name'] ?? '',
    );
  }
}
