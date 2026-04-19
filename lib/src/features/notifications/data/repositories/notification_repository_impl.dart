import 'package:dartz/dartz.dart';
import '../../../../core/error/exception.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/networking/network_info.dart';
import '../../../../core/utils/handlers/error_handler.dart';
import '../../../../core/utils/ressources/app_api_messages.dart';
import '../data_sources/notification_remote_data_source.dart';
import '../models/notification_model.dart';
import '../../domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NetworkInfo networkInfo;
  final NotificationRemoteDataSource remoteDataSource;

  NotificationRepositoryImpl({
    required this.networkInfo,
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, NotificationResponseModel>> getUnreadCount() async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getUnreadCount();
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: ErrorHandler.getErrorMessage(e)));
      }
    } else {
      return const Left(
          NoInternetConnectionFailure(message: AppApiResponsesMessages.noInternetConnection));
    }
  }

  @override
  Future<Either<Failure, NotificationResponseModel>> getNotifications(
      {int page = 0, int pageSize = 10}) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getNotifications(page: page, pageSize: pageSize);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: ErrorHandler.getErrorMessage(e)));
      }
    } else {
      return const Left(
          NoInternetConnectionFailure(message: AppApiResponsesMessages.noInternetConnection));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(int id) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.markAsRead(id);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: ErrorHandler.getErrorMessage(e)));
      }
    } else {
      return const Left(
          NoInternetConnectionFailure(message: AppApiResponsesMessages.noInternetConnection));
    }
  }
}
