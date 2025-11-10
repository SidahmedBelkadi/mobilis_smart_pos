import 'dart:io';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:mobilis_smart_pos/src/core/error/failure.dart';
import 'package:mobilis_smart_pos/src/features/sign_in/domain/repositories/sign_in_repository.dart';

class SignAndApproveContractUseCase {
  final SignInRepository repository;

  SignAndApproveContractUseCase({required this.repository});

  Future<Either<Failure, void>> call({required File signatureFile}) async {
    return await repository.signAndApproveContract(signatureFile: signatureFile);
  }
}
