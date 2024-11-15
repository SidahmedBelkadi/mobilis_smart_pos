import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/reset_password_request_otp_params.dart';
import '../repositories/reset_password_repository.dart';

class ResetPasswordOTPUseCase {
  final ResetPasswordRepository repository;

  ResetPasswordOTPUseCase({required this.repository});

  Future<Either<Failure, String>> resetPasswordOTP(
      {required ResetPasswordRequestOtpParams params}) async {
    return await repository.resetPasswordOTP(params: params);
  }
}
