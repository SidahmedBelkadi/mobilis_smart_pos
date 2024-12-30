import 'package:dartz/dartz.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/trigger_sms_params_entity.dart';

import '../../../../core/error/failure.dart';
import '../repositories/contract_repository.dart';

class RetryTrigggerSmsUseCase {
  final ContractRepository repository;

  RetryTrigggerSmsUseCase({required this.repository});

  Future<Either<Failure, Unit>> call({
    required TriggerSmsParamsEntity trigggerSmsParams,
  }) async {
    return await repository.retryTriggerSms(params: trigggerSmsParams);
  }
}
