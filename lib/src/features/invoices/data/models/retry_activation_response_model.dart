import 'package:mobilis_smart_pos/src/features/invoices/domain/entities/retry_activation_response_entity.dart';

class RetryActivationResponseModel extends RetryActivationResponseEntity {
  const RetryActivationResponseModel({
    required super.formattedStringSms,
    required super.generateContractUrl,
  });

  factory RetryActivationResponseModel.fromJson(Map<String, dynamic> json) {
    return RetryActivationResponseModel(
      formattedStringSms: json['formattedString'],
      generateContractUrl: json['api'],
    );
  }
}
