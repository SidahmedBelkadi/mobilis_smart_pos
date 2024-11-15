import '../../domain/entities/edit_contract_response_entity.dart';

class EditContractResponseModel extends EditContractResponseEntity {
  const EditContractResponseModel({
    required super.contractCode,
    required super.message,
    required super.contractMessage,
    required super.subscriptionId,
    required super.invoiceId,
    required super.clientId,
  });

  factory EditContractResponseModel.fromJson({required Map<String, dynamic> json}) {
    return EditContractResponseModel(
      subscriptionId: json['subscriptionID'],
      invoiceId: json['invoiceID'],
      clientId: json['clientId'],
      contractCode: json['contractCode'],
      message: json['message'],
      contractMessage: json['contract'],
    );
  }
}
