import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/generate_contract_params_entity.dart';
import '../entities/generate_contract_response_entity.dart';
import '../repositories/contract_repository.dart';

class GenerateContractUseCase {
  final ContractRepository repository;

  GenerateContractUseCase({required this.repository});

  Future<Either<Failure, GenerateContractResponseEntity>> call({
    required GenerateContractParamsEntity generateContractParams,
    required String lang,
  }) async {
    return await repository.generateContract(
        generateContractParams: generateContractParams, lang: lang);
  }
}
