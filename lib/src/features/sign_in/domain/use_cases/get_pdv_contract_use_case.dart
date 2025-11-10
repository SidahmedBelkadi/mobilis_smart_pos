import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:mobilis_smart_pos/src/core/error/failure.dart';
import 'package:mobilis_smart_pos/src/features/sign_in/domain/repositories/sign_in_repository.dart';

class GetPdvContractUseCase {
  final SignInRepository repository;

  GetPdvContractUseCase({required this.repository});

  Future<Either<Failure, Uint8List>> call() async {
    return await repository.getPdvContract();
  }
}
