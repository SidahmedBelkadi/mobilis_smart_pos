import 'package:mobilis_smart_pos/src/features/contract/domain/entities/retry_trigger_sms_response_entity.dart';

class RetryTriggerSmsResponseModel extends RetryTriggerSmsResponseEntity {
  const RetryTriggerSmsResponseModel({
    required super.subsId,
    required super.invoiceId,
    required super.clientId,
    required super.contractCode,
  });

  factory RetryTriggerSmsResponseModel.fromJson({required Map<String, dynamic> json}) {
    return RetryTriggerSmsResponseModel(
      subsId: json['subscriptionID'],
      invoiceId: json['invoiceID'],
      clientId: json['clientId'],
      contractCode: json['contractCode'],
    );
  }
}
