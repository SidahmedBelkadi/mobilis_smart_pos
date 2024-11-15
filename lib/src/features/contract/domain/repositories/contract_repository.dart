import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/check_before_edit_contract_response_entity.dart';
import '../entities/contract_request_params_entitiy.dart';
import '../entities/edit_contract_response_entity.dart';
import '../entities/generate_contract_params_entity.dart';
import '../entities/generate_contract_response_entity.dart';

abstract class ContractRepository {
  Future<Either<Failure, CheckBeforeEditContractResponseEntity>>
      checkBeforeEditContract({
    required ContractRequestParamsEntitiy contract,
  });

  Future<Either<Failure, EditContractResponseEntity>> editContract({
    required ContractRequestParamsEntitiy contract,
    required File? recto,
    required File? verso,
    required File? signature,
    required bool isPassport,
    required String pdvCode,
    required File? parentRecto,
    required File? parentVerso,
    required File? justifiatif,
    required bool? parentIsPassport,
  });

  Future<Either<Failure, GenerateContractResponseEntity>> generateContract({
    required GenerateContractParamsEntity generateContractParams,
  });
}
