import '../../domain/entities/check_before_edit_contract_response_entity.dart';

class CheckBeforeEditContractResponseModel extends CheckBeforeEditContractResponseEntity {
  const CheckBeforeEditContractResponseModel({required super.formattedStringWithoutSpaces});

  factory CheckBeforeEditContractResponseModel.fromJson(Map<String, dynamic> json) {
    return CheckBeforeEditContractResponseModel(
        formattedStringWithoutSpaces: json['formattedCode']);
  }
}
