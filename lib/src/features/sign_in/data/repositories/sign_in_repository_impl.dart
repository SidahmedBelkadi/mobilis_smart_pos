import 'dart:io';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import '../../domain/entities/sign_in_approve_contract_params.dart';

import '../../../../core/error/exception.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/networking/network_info.dart';
import '../../../../core/utils/handlers/error_handler.dart';
import '../../domain/entities/sign_in_otp_request_params.dart';
import '../../domain/entities/sign_in_otp_response_entity.dart';
import '../../domain/entities/sign_in_request_params.dart';
import '../../domain/entities/sign_in_response.dart';
import '../../domain/repositories/sign_in_repository.dart';
import '../data_sources/sign_in_remote_data_source.dart';

class SignInRepositoryImpl implements SignInRepository {
  final NetworkInfo networkInfo;
  final SignInRemoteDataSource remoteDataSource;

  SignInRepositoryImpl({required this.networkInfo, required this.remoteDataSource});

  @override
  Future<Either<Failure, SignInResponseEntity>> signIn({
    required SignInRequestParams params,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final sigInResponseModel = await remoteDataSource.signIn(params: params);
        return Right(sigInResponseModel);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: ErrorHandler.getErrorMessage(e)));
      }
    } else {
      return const Left(NoInternetConnectionFailure(message: 'noInternetConnection'));
    }
  }

  @override
  Future<Either<Failure, SignInOTPResponseEntity>> verifyOTP(
      {required SignInOTPRequestParams params}) async {
    if (await networkInfo.isConnected) {
      try {
        final signInOTPResponseModel = await remoteDataSource.verifyOTP(params: params);
        return Right(signInOTPResponseModel);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: ErrorHandler.getErrorMessage(e)));
      }
    } else {
      return const Left(NoInternetConnectionFailure(message: 'noInternetConnection'));
    }
  }

  @override
  Future<Either<Failure, String>> approveContract(
      {required SignInApproveContractParams params}) async {
    if (await networkInfo.isConnected) {
      try {
        final message = await remoteDataSource.approveContract(params: params);
        return Right(message);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: ErrorHandler.getErrorMessage(e)));
      }
    } else {
      return const Left(NoInternetConnectionFailure(message: 'noInternetConnection'));
    }
  }

  @override
  Future<Either<Failure, Uint8List>> getPdvContract() async {
    if (await networkInfo.isConnected) {
      try {
        final pdvContract = await remoteDataSource.getPdvContract();
        return Right(pdvContract);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: ErrorHandler.getErrorMessage(e)));
      }
    } else {
      return const Left(NoInternetConnectionFailure(message: 'noInternetConnection'));
    }
  }

  @override
  Future<Either<Failure, void>> signAndApproveContract({required File signatureFile}) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.signAndApproveContract(signatureFile: signatureFile);
        return const Right(unit);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: ErrorHandler.getErrorMessage(e)));
      }
    } else {
      return const Left(NoInternetConnectionFailure(message: 'noInternetConnection'));
    }
  }
}
