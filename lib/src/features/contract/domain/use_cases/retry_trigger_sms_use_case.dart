import 'package:dartz/dartz.dart';
import 'package:mobilis_smart_pos/src/core/error/failure.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/retry_trigger_sms_params_entity.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/retry_trigger_sms_response_entity.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/repositories/contract_repository.dart';

class RetryTrigggerSmsUseCase {
  final ContractRepository repository;

  RetryTrigggerSmsUseCase({required this.repository});

  Future<Either<Failure, RetryTriggerSmsResponseEntity>> call({
    required RetryTriggerSmsParamsEntity trigggerSmsParams,
  }) async {
    return await repository.retryTriggerSms(params: trigggerSmsParams);
  }
}
