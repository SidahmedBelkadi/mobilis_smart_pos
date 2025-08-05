import '../../domain/entities/edit_contract_response_entity.dart';

class EditContractResponseModel extends EditContractResponseEntity {
  const EditContractResponseModel({required super.message, required super.msisdn});

  factory EditContractResponseModel.fromJson({required Map<String, dynamic> json}) {
    return EditContractResponseModel(
      message: json['message'],
      msisdn: json['msisdn'],
    );
  }
}
