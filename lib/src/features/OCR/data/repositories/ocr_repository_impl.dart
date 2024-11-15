import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/error/exception.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/networking/network_info.dart';
import '../../../../core/utils/handlers/error_handler.dart';
import '../../../../core/utils/ressources/app_api_messages.dart';
import '../../domain/entities/id_card_response_entity.dart';
import '../../domain/entities/passport_response_entity.dart';
import '../../domain/repositories/ocr_repository.dart';
import '../data_sources/ocr_data_source.dart';

class OcrRepositoryImpl implements OcrRepository {
  final NetworkInfo networkInfo;
  final OcrDataSource dataSource;

  OcrRepositoryImpl({required this.networkInfo, required this.dataSource});

  @override
  Future<Either<Failure, IdCardResponse>> processId({
    required File front,
    required File back,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final idResponseModel = await dataSource.processId(front: front, back: back);
        return Right(idResponseModel);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: ErrorHandler.getErrorMessage(e)));
      }
    } else {
      return const Left(
          NoInternetConnectionFailure(message: AppApiResponsesMessages.noInternetConnection));
    }
  }

  @override
  Future<Either<Failure, PassportResponse>> processPassport({required File front}) async {
    if (await networkInfo.isConnected) {
      try {
        final passportResponseModel = await dataSource.processPassport(front: front);
        return Right(passportResponseModel);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: ErrorHandler.getErrorMessage(e)));
      }
    } else {
      return const Left(
          NoInternetConnectionFailure(message: AppApiResponsesMessages.noInternetConnection));
    }
  }
}
