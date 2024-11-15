import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/contract_request_params_entitiy.dart';
import '../entities/edit_contract_response_entity.dart';
import '../repositories/contract_repository.dart';

class EditContractUseCase {
  final ContractRepository repository;

  EditContractUseCase({required this.repository});

  Future<Either<Failure, EditContractResponseEntity>> call({
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
  }) async {
    return await repository.editContract(
      contract: contract,
      recto: recto,
      verso: verso,
      signature: signature,
      isPassport: isPassport,
      pdvCode: pdvCode,
      parentRecto: parentRecto,
      parentVerso: parentVerso,
      justifiatif: justifiatif,
      parentIsPassport: parentIsPassport,
    );
  }
}
