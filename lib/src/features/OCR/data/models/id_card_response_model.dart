import '../../domain/entities/id_card_response_entity.dart';

class IdCardResponseModel extends IdCardResponse {
  IdCardResponseModel({
    required super.firstName,
    required super.lastName,
    required super.birthDate,
    required super.gender,
    required super.idNum,
    required super.issueDate,
    required super.expirationDate,
    required super.signature,
    required super.document,
    required super.birthPlace,
    required super.nin,
    required super.issueAuthority,
    required super.photo,
  });

  factory IdCardResponseModel.fromJson({required Map<String, dynamic> json}) {
    return IdCardResponseModel(
      firstName: json['firstName'],
      lastName: json['lastName'],
      birthDate: json['birthDate'],
      gender: json['gender'],
      idNum: json['idNum'],
      issueDate: json['issueDate'],
      expirationDate: json['expirationDate'],
      signature: json['signature'],
      document: json['document'],
      birthPlace: json['birthPlace'],
      nin: json['NIN'],
      issueAuthority: json['issueAuthority'],
      photo: json['photo'],
    );
  }
}
