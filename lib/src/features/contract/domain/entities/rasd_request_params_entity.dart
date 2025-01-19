import 'package:mobilis_smart_pos/src/features/sign_in/data/data_sources/smart_pos_local_storage.dart';

import '../../../../dependency_injection/injection_container.dart' as di;

class RasdRequestParamsEntity {
  final String firstName;
  final String birthLastName;
  final String gender;
  final String birthDate;
  final String birthPlace;
  final String? nationality;
  final String wilayaId;
  final String street;
  final String commune;
  final String? authority;
  final String email;
  final String documentType;
  final String documentNumber;
  final String issueDate;
  final int? subscriptionTypeId;
  final String? folderFiles;
  final int? serialNumber;
  final String address;

  RasdRequestParamsEntity({
    required this.firstName,
    required this.birthLastName,
    required this.gender,
    required this.birthDate,
    required this.birthPlace,
    this.nationality,
    required this.wilayaId,
    required this.street,
    required this.commune,
    this.authority,
    required this.email,
    required this.documentType,
    required this.documentNumber,
    required this.issueDate,
    this.subscriptionTypeId,
    this.folderFiles,
    this.serialNumber,
    required this.address,
  });

  Map<String, dynamic> toJson() {
    return {
      'First_name': firstName,
      'Birth_last_name': birthLastName,
      'Gender': gender,
      'Birth_date': birthDate,
      'Birth_place': birthPlace,
      'Nationality': nationality,
      'Wilaya_id': wilayaId,
      'Street': street,
      'Commune': commune,
      'Authority': authority,
      'email': email,
      'Document_type': documentType,
      'Document_number': documentNumber,
      'Issue_date': issueDate,
      'Subscription_type_ID': subscriptionTypeId,
      'Folder_files': folderFiles,
      'PDV_ID': di.serviceLocator<SmartPosLocalStorage>().getSavedLoginCredentials()!.userId,
      'Employee_ID':
          di.serviceLocator<SmartPosLocalStorage>().getSavedLoginCredentials()!.employeeId,
      'serial_number': serialNumber,
    };
  }

  RasdRequestParamsEntity copyWith({
    String? firstName,
    String? birthLastName,
    String? gender,
    String? birthDate,
    String? birthPlace,
    String? nationality,
    String? wilayaId,
    String? street,
    String? commune,
    String? authority,
    String? email,
    String? documentType,
    String? documentNumber,
    String? issueDate,
    int? subscriptionTypeId,
    String? folderFiles,
    int? serialNumber,
    String? address,
  }) {
    return RasdRequestParamsEntity(
      firstName: firstName ?? this.firstName,
      birthLastName: birthLastName ?? this.birthLastName,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      birthPlace: birthPlace ?? this.birthPlace,
      nationality: nationality ?? this.nationality,
      wilayaId: wilayaId ?? this.wilayaId,
      street: street ?? this.street,
      commune: commune ?? this.commune,
      authority: authority ?? this.authority,
      email: email ?? this.email,
      documentType: documentType ?? this.documentType,
      documentNumber: documentNumber ?? this.documentNumber,
      issueDate: issueDate ?? this.issueDate,
      subscriptionTypeId: subscriptionTypeId ?? this.subscriptionTypeId,
      folderFiles: folderFiles ?? this.folderFiles,
      serialNumber: serialNumber ?? this.serialNumber,
      address: address ?? this.address,
    );
  }
}
