class Commune {
  final int id;
  final String code;
  final String name;
  final String arName;
  final String stateCode;

  Commune({
    required this.id,
    required this.code,
    required this.name,
    required this.arName,
    required this.stateCode,
  });

  factory Commune.fromJson(Map<String, dynamic> json) {
    return Commune(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      arName: json['ar_name'] ?? '',
      stateCode: json['code_wilaya'] ?? '',
    );
  }
}
