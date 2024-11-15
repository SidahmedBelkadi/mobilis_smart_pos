import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/sign_in_otp_request_params.dart';
import '../entities/sign_in_otp_response_entity.dart';
import '../repositories/sign_in_repository.dart';

class VerifyOtpUseCase {
  final SignInRepository repository;

  VerifyOtpUseCase({required this.repository});

  Future<Either<Failure, SignInOTPResponseEntity>> call({
    required SignInOTPRequestParams params,
  }) async {
    return await repository.verifyOTP(params: params);
  }
}
