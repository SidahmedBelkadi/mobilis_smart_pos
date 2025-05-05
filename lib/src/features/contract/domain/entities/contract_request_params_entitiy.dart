// ignore_for_file: public_member_api_docs, sort_constructors_first
class ContractRequestParamsEntitiy {
  // ==== Client Info === //
  final String firstName;
  final String lastName;
  final String gender;
  final String birthDate;
  String? presumedBirthDate;
  final String birthPlace;
  final String nationality;
  final int wilayaId;
  final String commune;
  final String street;
  final String? folderUrl;
  String? email;
  final int? employeeId;

  // Subscription
  int? subscriptionId;

  // ==== Client Civils Info === //
  final String nin;
  final String documentType;
  final String documentNumber;
  final String issuingCountry;
  final String issuingPlace;
  final String issueDate;
  final String bloodGroup;
  String? msisdn;

  // =========== Parent Info === //
  String? parentFirstName;
  String? parentLastName;
  String? parentGender;
  String? parentBirthDate;
  String? parentBirthPlace;
  String? parentNationality;
  int? parentWilayaId;
  String? parentCommune;
  String? parentStreet;

  // ==== Parents Civils Info === //
  String? parentNin;
  String? parentDocumentType;
  String? parentDocumentNumber;
  String? parentIssuingCountry;
  String? parentIssuingPlace;
  String? parentIssueDate;
  String? parentBloodGroup;

  // ==== PDV === //
  final int pdvId;
  int? serialNumber;

  ContractRequestParamsEntitiy({
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.birthDate,
    this.presumedBirthDate,
    required this.birthPlace,
    required this.nationality,
    required this.wilayaId,
    required this.commune,
    required this.street,
    required this.folderUrl,
    required this.nin,
    required this.documentType,
    required this.documentNumber,
    required this.issuingCountry,
    required this.issuingPlace,
    required this.issueDate,
    required this.bloodGroup,
    required this.pdvId,
    this.serialNumber,
    this.email,
    this.employeeId,

    // Subscription

    this.subscriptionId,

    // =========== //

    this.parentFirstName,
    this.parentLastName,
    this.parentGender,
    this.parentBirthDate,
    this.parentBirthPlace,
    this.parentNationality,
    this.parentWilayaId,
    this.parentCommune,
    this.parentStreet,

    // ==== Parents Civils Info === //
    this.parentNin,
    this.parentDocumentType,
    this.parentDocumentNumber,
    this.parentIssuingCountry,
    this.parentIssuingPlace,
    this.parentIssueDate,
    this.parentBloodGroup,
  });

  Map<String, dynamic> toJson() {
    dynamic civilsDocuments = {
      "NIN": nin,
      "Bloodgroup": bloodGroup,
      "Issuing_country": issuingCountry,
      "Document_type": documentType,
      "Document_number": documentNumber,
      "Issue_date": issueDate,
      "Issue_place": issuingPlace
    };
    final Map<String, dynamic> subscription = {
      // "Subscription_type_ID": subscriptionId ?? 1,
      "Start_date": DateTime.now().toIso8601String(),
      "End_date": DateTime.now()
          .add(
            const Duration(days: 365),
          )
          .toIso8601String(),
      "Folder_files": folderUrl,
    };

    final Map<String, dynamic> invoice = {
      "PDV_ID": pdvId,
    };
    if (employeeId != null) {
      invoice['Employee_ID'] = employeeId;
    }

    if (serialNumber != null) {
      invoice['serial_number'] = serialNumber;
    }

    Map<String, dynamic> parent = {};

    if (parentFirstName != null) {
      parent = {
        "First_name": parentFirstName,
        "Birth_last_name": parentLastName,
        "Gender": parentGender,
        "Birth_date": parentBirthDate,
        "Birth_place": parentBirthPlace,
        "Nationality": parentNationality,
        "Wilaya_id": parentWilayaId,
        "Street": parentStreet,
        "Commune": parentCommune,
        "Authority": parentIssuingPlace
      };

      civilsDocuments = [
        {
          "NIN": nin,
          "Bloodgroup": bloodGroup,
          "Issuing_country": issuingCountry,
          "Document_type": documentType,
          "Document_number": documentNumber,
          "Issue_date": issueDate,
          "Issue_place": issuingPlace
        },
        {
          "NIN": parentNin,
          "Bloodgroup": "",
          "Issuing_country": parentIssuingCountry,
          "Document_type": parentDocumentType,
          "Document_number": parentDocumentNumber,
          "Issue_date": parentIssueDate,
          "Issue_place": parentIssuingPlace
        }
      ];
    }

    return {
      "client": {
        "First_name": firstName,
        "Birth_last_name": lastName,
        "Gender": gender,
        "Birth_date": birthDate,
        "Presumed_birth_date": presumedBirthDate,
        "Birth_place": birthPlace,
        "Nationality": nationality,
        "Wilaya_id": wilayaId,
        "Street": street,
        "Commune": commune,
        "Authority": issuingPlace,
        "email": email,
      },
      "parent": parent,
      "civil_documents": civilsDocuments,
      "subscription": subscription,
      "invoice": invoice,
    };
  }

  ContractRequestParamsEntitiy copyWith({
    String? firstName,
    String? lastName,
    String? gender,
    String? birthDate,
    String? birthPlace,
    String? nationality,
    int? wilayaId,
    String? daira,
    String? commune,
    String? street,
    String? folderUrl,
    String? nin,
    String? documentType,
    String? documentNumber,
    String? issuingCountry,
    String? issuingPlace,
    String? issueDate,
    String? bloodGroup,
    String? email,
    int? pdvId,
    int? serialNumber,
    int? employeeId,
    int? subscriptionId,
    String? parentFirstName,
    String? parentLastName,
    String? parentGender,
    String? parentBirthDate,
    String? parentBirthPlace,
    String? parentNationality,
    int? parentWilayaId,
    String? parentDaira,
    String? parentCommune,
    String? parentStreet,
    String? parentNin,
    String? parentDocumentType,
    String? parentDocumentNumber,
    String? parentIssuingCountry,
    String? parentIssuingPlace,
    String? parentIssueDate,
    String? parentBloodGroup,
  }) {
    return ContractRequestParamsEntitiy(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      birthPlace: birthPlace ?? this.birthPlace,
      nationality: nationality ?? this.nationality,
      wilayaId: wilayaId ?? this.wilayaId,
      commune: commune ?? this.commune,
      street: street ?? this.street,
      folderUrl: folderUrl ?? this.folderUrl,
      nin: nin ?? this.nin,
      documentType: documentType ?? this.documentType,
      documentNumber: documentNumber ?? this.documentNumber,
      issuingCountry: issuingCountry ?? this.issuingCountry,
      issuingPlace: issuingPlace ?? this.issuingPlace,
      issueDate: issueDate ?? this.issueDate,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      email: email ?? this.email,
      pdvId: pdvId ?? this.pdvId,
      serialNumber: serialNumber ?? this.serialNumber,
      employeeId: employeeId ?? this.employeeId,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      parentFirstName: parentFirstName ?? this.parentFirstName,
      parentLastName: parentLastName ?? this.parentLastName,
      parentGender: parentGender ?? this.parentGender,
      parentBirthDate: parentBirthDate ?? this.parentBirthDate,
      parentBirthPlace: parentBirthPlace ?? this.parentBirthPlace,
      parentNationality: parentNationality ?? this.parentNationality,
      parentWilayaId: parentWilayaId ?? this.parentWilayaId,
      parentCommune: parentCommune ?? this.parentCommune,
      parentStreet: parentStreet ?? this.parentStreet,
      parentNin: parentNin ?? this.parentNin,
      parentDocumentType: parentDocumentType ?? this.parentDocumentType,
      parentDocumentNumber: parentDocumentNumber ?? this.parentDocumentNumber,
      parentIssuingCountry: parentIssuingCountry ?? this.parentIssuingCountry,
      parentIssuingPlace: parentIssuingPlace ?? this.parentIssuingPlace,
      parentIssueDate: parentIssueDate ?? this.parentIssueDate,
      parentBloodGroup: parentBloodGroup ?? this.parentBloodGroup,
    );
  }

  @override
  String toString() {
    return 'ContractRequestParamsEntitiy(firstName: $firstName, lastName: $lastName, gender: $gender, birthDate: $birthDate, birthPlace: $birthPlace, nationality: $nationality, wilayaId: $wilayaId, commune: $commune, street: $street, Folder_Files: $folderUrl, email: $email, nin: $nin, documentType: $documentType, documentNumber: $documentNumber, issuingCountry: $issuingCountry, issuingPlace: $issuingPlace, issueDate: $issueDate, bloodGroup: $bloodGroup, msisdn: $msisdn, pdvId: $pdvId, serialNumber: $serialNumber)';
  }
}
