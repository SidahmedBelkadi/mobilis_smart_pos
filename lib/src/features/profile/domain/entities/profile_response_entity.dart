import 'package:equatable/equatable.dart';

class ProfileResponseEntity extends Equatable {
  final String fullName;
  final String entrepriseName;
  final String msisdnAPN;
  final String msisdnErselli;
  final String secretCode;
  final String commercialRegister;
  final String nif;
  final String address;
  final String folderFiles;

  const ProfileResponseEntity({
    required this.fullName,
    required this.entrepriseName,
    required this.msisdnAPN,
    required this.msisdnErselli,
    required this.secretCode,
    required this.commercialRegister,
    required this.nif,
    required this.address,
    required this.folderFiles,
  });

  @override
  List<Object?> get props => [
        fullName,
        entrepriseName,
        msisdnAPN,
        msisdnErselli,
        secretCode,
        commercialRegister,
        nif,
        address,
        folderFiles
      ];
}
