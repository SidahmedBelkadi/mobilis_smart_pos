import 'package:dartz/dartz.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/rasd_trigger_sms_params_entity.dart';

import '../../../../core/error/failure.dart';
import '../repositories/contract_repository.dart';

class RasdTrigggerSmsUseCase {
  final ContractRepository repository;

  RasdTrigggerSmsUseCase({required this.repository});

  Future<Either<Failure, String>> call({
    required RasdTriggerSmsParamsEntity trigggerSmsParams,
  }) async {
    return await repository.rasdTriggerSms(rasdTriggerSmsParamsEntity: trigggerSmsParams);
  }
}
