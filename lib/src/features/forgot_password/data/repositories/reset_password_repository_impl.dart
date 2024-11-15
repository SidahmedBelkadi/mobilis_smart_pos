import 'package:dartz/dartz.dart';

import '../../../../core/error/exception.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/networking/network_info.dart';
import '../../../../core/utils/handlers/error_handler.dart';
import '../../domain/entities/reset_password_params.dart';
import '../../domain/entities/reset_password_request_otp_params.dart';
import '../../domain/repositories/reset_password_repository.dart';
import '../data_sources/reset_password_remote_data_source.dart';

class ResetPasswordRepositoryImpl implements ResetPasswordRepository {
  final NetworkInfo networkInfo;
  final ResetPasswordRemoteDataSource remoteDataSource;

  ResetPasswordRepositoryImpl({required this.networkInfo, required this.remoteDataSource});

  @override
  Future<Either<Failure, String>> resetPassword({required ResetPasswordParams params}) async {
    if (await networkInfo.isConnected) {
      try {
        final message = await remoteDataSource.resetPassword(params: params);
        return Right(message);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: ErrorHandler.getErrorMessage(e)));
      }
    } else {
      return const Left(NoInternetConnectionFailure(message: 'noInternetConnection'));
    }
  }

  @override
  Future<Either<Failure, String>> resetPasswordOTP(
      {required ResetPasswordRequestOtpParams params}) async {
    if (await networkInfo.isConnected) {
      try {
        final message = await remoteDataSource.resetPasswordRequestOTP(params: params);
        return Right(message);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: ErrorHandler.getErrorMessage(e)));
      }
    } else {
      return const Left(NoInternetConnectionFailure(message: 'noInternetConnection'));
    }
  }
}
