// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';

class IdCardResponse extends Equatable {
  final String firstName;
  final String lastName;
  final String birthDate;
  final String gender;
  final String idNum;
  final String issueDate;
  final String expirationDate;
  final String signature;
  final String document;
  final String birthPlace;
  final String nin;
  final String issueAuthority;
  final String photo;

  const IdCardResponse({
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.gender,
    required this.idNum,
    required this.issueDate,
    required this.expirationDate,
    required this.signature,
    required this.document,
    required this.birthPlace,
    required this.nin,
    required this.issueAuthority,
    required this.photo,
  });

  @override
  List<Object?> get props => [
        firstName,
        lastName,
        birthDate,
        gender,
        idNum,
        issueDate,
        expirationDate,
        signature,
        document,
        birthDate,
        nin,
        issueAuthority,
        photo
      ];

  @override
  bool get stringify => true;
}
