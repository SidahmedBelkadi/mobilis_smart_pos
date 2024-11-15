class Wilaya {
  final int id;
  final String code;
  final String name;
  final String arName;

  Wilaya({
    required this.id,
    required this.code,
    required this.name,
    required this.arName,
  });

  factory Wilaya.fromJson(Map<String, dynamic> json) {
    return Wilaya(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      arName: json['ar_name'] ?? '',
    );
  }
}
