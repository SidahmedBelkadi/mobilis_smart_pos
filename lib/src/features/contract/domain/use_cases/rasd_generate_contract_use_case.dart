import 'package:dartz/dartz.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/generate_contract_response_entity.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/rasd_generate_contract_params_entity.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/repositories/contract_repository.dart';

import '../../../../core/error/failure.dart';

class RasdGenerateContractUseCase {
  final ContractRepository repository;

  RasdGenerateContractUseCase({required this.repository});

  Future<Either<Failure, GenerateContractResponseEntity>> call({
    required RasdGenerateContractParamsEntity rasdGenerateContractParams,
    required int subscriptionId,
  }) async {
    return await repository.rasdGenerateContract(
      rasdGenerateContractParams: rasdGenerateContractParams,
      subscriptionId: subscriptionId,
    );
  }
}
