import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/error/exception.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/networking/network_info.dart';
import '../../../../core/utils/handlers/error_handler.dart';
import '../../domain/entities/profile_response_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../data_sources/profile_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final NetworkInfo networkInfo;
  final ProfileDataSource remoteDataSource;

  ProfileRepositoryImpl(
      {required this.networkInfo, required this.remoteDataSource});

  @override
  Future<Either<Failure, ProfileResponseEntity>> getPDVInfo(
      {required int pdvID}) async {
    if (await networkInfo.isConnected) {
      try {
        final profileResponseModel =
            await remoteDataSource.getPDVInfo(pdvID: pdvID);
        return Right(profileResponseModel);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: ErrorHandler.getErrorMessage(e)));
      }
    } else {
      return const Left(
          NoInternetConnectionFailure(message: 'noInternetConnection'));
    }
  }

  @override
  Future<Either<Failure, void>> updatePDVInfo({
    required String employeeId,
    required String pdvCode,
    required bool isPassport,
    required File recto,
    required File? verso,
    required File commercialRgister,
    required File nif,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.updatePDVInfo(
          employeeId: employeeId,
          pdvCode: pdvCode,
          isPassport: isPassport,
          recto: recto,
          verso: verso,
          commercialRgister: commercialRgister,
          nif: nif,
        );
        return Right(response);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: ErrorHandler.getErrorMessage(e)));
      }
    } else {
      return const Left(
          NoInternetConnectionFailure(message: 'noInternetConnection'));
    }
  }

  @override
  Future<Either<Failure, List>> getPdvImages({
    required String pdvCode,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.getPdvImages(pdvCode: pdvCode);
        return right(response);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: ErrorHandler.getErrorMessage(e)));
      }
    } else {
      return const Left(
          NoInternetConnectionFailure(message: 'noInternetConnection'));
    }
  }
}
