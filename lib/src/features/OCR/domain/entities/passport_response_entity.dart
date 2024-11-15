// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';

class PassportResponse extends Equatable {
  final String document;
  final String firstName;
  final String lastName;
  final String birthDate;
  final String birthPlace;
  final String gender;
  final String nationality;
  final String nin;
  final String passportNum;
  final String issueAuthority;
  final String issueDate;
  final String expirationDate;
  final String signature;
  final String photo;

  const PassportResponse({
    required this.document,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.birthPlace,
    required this.gender,
    required this.nationality,
    required this.nin,
    required this.passportNum,
    required this.issueAuthority,
    required this.issueDate,
    required this.expirationDate,
    required this.signature,
    required this.photo,
  });

  @override
  List<Object?> get props => [
        document,
        firstName,
        lastName,
        birthDate,
        birthPlace,
        gender,
        nationality,
        nin,
        passportNum,
        issueAuthority,
        issueDate,
        expirationDate,
        signature,
        photo,
      ];

  @override
  bool get stringify => true;
}
