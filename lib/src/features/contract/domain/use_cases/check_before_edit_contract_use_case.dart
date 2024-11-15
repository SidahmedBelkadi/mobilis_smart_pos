import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/check_before_edit_contract_response_entity.dart';
import '../entities/contract_request_params_entitiy.dart';
import '../repositories/contract_repository.dart';

class CheckBeforeEditContractUseCase {
  final ContractRepository repository;

  CheckBeforeEditContractUseCase({required this.repository});

  Future<Either<Failure, CheckBeforeEditContractResponseEntity>> call({
    required ContractRequestParamsEntitiy contract,
  }) async {
    return await repository.checkBeforeEditContract(
      contract: contract,
    );
  }
}
