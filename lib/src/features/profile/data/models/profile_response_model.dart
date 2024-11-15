import '../../domain/entities/profile_response_entity.dart';

class ProfileResponseModel extends ProfileResponseEntity {
  const ProfileResponseModel({
    required super.fullName,
    required super.entrepriseName,
    required super.msisdnAPN,
    required super.msisdnErselli,
    required super.secretCode,
    required super.commercialRegister,
    required super.nif,
    required super.address,
    required super.folderFiles,
  });

  factory ProfileResponseModel.fromJson({required Map<String, dynamic> json}) {
    return ProfileResponseModel(
      fullName: json['full_name'],
      entrepriseName: json['business_name'],
      msisdnAPN: json['msisdn'],
      msisdnErselli: json['msisdn_arselli'],
      secretCode: json['secret_code'],
      commercialRegister: json['register_commerce'],
      nif: json['nif'],
      address: json['street'],
      folderFiles: json['folder_files'],
    );
  }
}
