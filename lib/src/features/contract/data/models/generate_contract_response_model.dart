import '../../domain/entities/generate_contract_response_entity.dart';

class GenerateContractResponseModel extends GenerateContractResponseEntity {
  const GenerateContractResponseModel({required super.message, required super.contractMessage});

  factory GenerateContractResponseModel.fromJson({required Map<String, dynamic> json}) {
    return GenerateContractResponseModel(
      message: json['message'],
      contractMessage: json['contract'],
    );
  }
}
