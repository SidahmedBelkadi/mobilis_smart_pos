import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/check_client_params_entity.dart';
import '../repositories/contract_repository.dart';

class CheckClientUseCase {
  final ContractRepository repository;

  CheckClientUseCase({required this.repository});

  Future<Either<Failure, Unit>> call({required CheckClientParamsEntity params}) async {
    return await repository.checkClient(params: params);
  }
}
