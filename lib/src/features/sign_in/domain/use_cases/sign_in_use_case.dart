import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/sign_in_request_params.dart';
import '../entities/sign_in_response.dart';
import '../repositories/sign_in_repository.dart';

class SignInUseCase {
  final SignInRepository repository;

  SignInUseCase({required this.repository});

  Future<Either<Failure, SignInResponseEntity>> call({required SignInRequestParams params}) async {
    return await repository.signIn(params: params);
  }
}
