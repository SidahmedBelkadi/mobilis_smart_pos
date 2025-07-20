import 'package:mobilis_smart_pos/src/features/contract/domain/entities/rasd_edit_contract_response_entity.dart';

class RasdEditContractResponseModel extends RasdEditContractResponseEntity {
  const RasdEditContractResponseModel({
    required super.message,
  });

  factory RasdEditContractResponseModel.fromJson({required Map<String, dynamic> json}) {
    return RasdEditContractResponseModel(
      message: json['message'],
    );
  }
}
