import 'package:dartz/dartz.dart';
import 'package:mobilis_smart_pos/src/core/error/failure.dart';
import 'package:mobilis_smart_pos/src/features/bar_code/domain/entities/offer_entity.dart';

abstract class OffersRepository {
  Future<Either<Failure, List<OfferEntity>>> getAllOffers();
}
