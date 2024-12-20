import 'package:dartz/dartz.dart';
import 'package:mobilis_smart_pos/src/features/bar_code/domain/entities/offer_entity.dart';
import 'package:mobilis_smart_pos/src/features/bar_code/domain/repositories/offers_repository.dart';

import '../../../../core/error/failure.dart';

class GetAllOffersUseCase {
  final OffersRepository repository;

  GetAllOffersUseCase({required this.repository});

  Future<Either<Failure, List<OfferEntity>>> call() async {
    return await repository.getAllOffers();
  }
}
