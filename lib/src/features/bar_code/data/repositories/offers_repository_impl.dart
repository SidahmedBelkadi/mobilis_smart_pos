import 'package:dartz/dartz.dart';
import 'package:mobilis_smart_pos/src/core/error/exception.dart';
import 'package:mobilis_smart_pos/src/core/error/failure.dart';
import 'package:mobilis_smart_pos/src/core/networking/network_info.dart';
import 'package:mobilis_smart_pos/src/core/utils/handlers/error_handler.dart';
import 'package:mobilis_smart_pos/src/features/bar_code/data/data_sources/offers_remote_data_source.dart';
import 'package:mobilis_smart_pos/src/features/bar_code/domain/entities/offer_entity.dart';
import 'package:mobilis_smart_pos/src/features/bar_code/domain/repositories/offers_repository.dart';

class OffersRepositoryImpl implements OffersRepository {
  final NetworkInfo networkInfo;
  final OffersRemoteDataSource remoteDataSource;

  OffersRepositoryImpl({
    required this.networkInfo,
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, List<OfferEntity>>> getAllOffers() async {
    if (await networkInfo.isConnected) {
      try {
        final List<OfferEntity> offers = await remoteDataSource.getAllOffers();
        return Right(offers);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: ErrorHandler.getErrorMessage(e)));
      }
    } else {
      return const Left(NoInternetConnectionFailure(message: 'noInternetConnection'));
    }
  }
}
