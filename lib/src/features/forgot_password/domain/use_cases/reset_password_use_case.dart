import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/reset_password_params.dart';
import '../repositories/reset_password_repository.dart';

class ResetPasswordUseCase {
  final ResetPasswordRepository repository;

  ResetPasswordUseCase({required this.repository});

  Future<Either<Failure, String>> call({required ResetPasswordParams params}) async {
    return await repository.resetPassword(params: params);
  }
}
