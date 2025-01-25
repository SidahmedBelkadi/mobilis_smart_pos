import 'package:mobilis_smart_pos/src/features/contract/domain/entities/rasd_edit_contract_response_entity.dart';

class RasdEditContractResponseModel extends RasdEditContractResponseEntity {
  const RasdEditContractResponseModel({
    required super.subscriptionID,
    required super.contractCode,
  });

  factory RasdEditContractResponseModel.fromJson({required Map<String, dynamic> json}) {
    return RasdEditContractResponseModel(
      subscriptionID: json['subscriptionID'],
      contractCode: json['contractCode'],
    );
  }
}
