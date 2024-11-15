import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/reset_password_params.dart';
import '../entities/reset_password_request_otp_params.dart';

abstract class ResetPasswordRepository {
  Future<Either<Failure, String>> resetPasswordOTP({required ResetPasswordRequestOtpParams params});
  Future<Either<Failure, String>> resetPassword({required ResetPasswordParams params});
}
