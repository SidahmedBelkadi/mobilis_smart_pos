import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/sign_in_approve_contract_params.dart';
import '../repositories/sign_in_repository.dart';

class ApproveContractUseCase {
  final SignInRepository repository;

  ApproveContractUseCase({required this.repository});

  Future<Either<Failure, String>> call({required SignInApproveContractParams params}) async {
    return await repository.approveContract(params: params);
  }
}
