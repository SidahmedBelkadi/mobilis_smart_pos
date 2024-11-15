import '../../domain/entities/passport_response_entity.dart';

class PassportResponseModel extends PassportResponse {
  const PassportResponseModel({
    required super.document,
    required super.firstName,
    required super.lastName,
    required super.birthDate,
    required super.birthPlace,
    required super.gender,
    required super.nationality,
    required super.nin,
    required super.passportNum,
    required super.issueAuthority,
    required super.issueDate,
    required super.expirationDate,
    required super.signature,
    required super.photo,
  });

  factory PassportResponseModel.fromJson({required Map<String, dynamic> json}) {
    return PassportResponseModel(
      document: json['document'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      birthDate: json['birthDate'],
      birthPlace: json['birthPlace'],
      gender: json['gender'],
      nationality: json['nationality'],
      nin: json['NIN'],
      passportNum: json['passportNum'],
      issueAuthority: json['issueAuthority'],
      issueDate: json['issueDate'],
      expirationDate: json['expirationDate'],
      signature: json['signature'],
      photo: json['photo'],
    );
  }
}
