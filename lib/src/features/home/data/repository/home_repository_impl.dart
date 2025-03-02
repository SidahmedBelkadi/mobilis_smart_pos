import 'package:dartz/dartz.dart';
import 'package:mobilis_smart_pos/src/core/error/failure.dart';
import 'package:mobilis_smart_pos/src/core/networking/network_info.dart';
import 'package:mobilis_smart_pos/src/features/home/data/data_sources/home_remote_data_source.dart';
import 'package:mobilis_smart_pos/src/features/home/domain/repository/home_repository.dart';

import '../../../../core/error/exception.dart';
import '../../../../core/utils/handlers/error_handler.dart';
import '../../../../core/utils/ressources/app_api_messages.dart';

class HomeRepositoryImpl implements HomeRepository {
  final NetworkInfo networkInfo;
  final HomeRemoteDataSource remoteDataSource;

  HomeRepositoryImpl({
    required this.networkInfo,
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, List<String>>> loadBanners() async {
    if (await networkInfo.isConnected) {
      try {
        final List<String> bannersUrl = await remoteDataSource.loadBanners();
        return Right(bannersUrl);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: ErrorHandler.getErrorMessage(e)));
      }
    } else {
      return const Left(
          NoInternetConnectionFailure(message: AppApiResponsesMessages.noInternetConnection));
    }
  }
}
