import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/rasd_edit_contract_response_entity.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/rasd_request_params_entity.dart';

import '../../../../core/error/failure.dart';
import '../repositories/contract_repository.dart';

class RasdEditContractUseCase {
  final ContractRepository repository;

  RasdEditContractUseCase({required this.repository});

  Future<Either<Failure, RasdEditContractResponseEntity>> call({
    required RasdEditRequestParamsEntity rasdEditRequestParamsEntity,
    required File? recto,
    required File? verso,
    required File? signature,
  }) async {
    return await repository.rasdEditContract(
        rasdEditRequestParamsEntity: rasdEditRequestParamsEntity,
        recto: recto,
        verso: verso,
        signature: signature);
  }
}
