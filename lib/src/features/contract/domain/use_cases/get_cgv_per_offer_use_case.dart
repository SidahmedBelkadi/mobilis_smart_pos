import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../repositories/contract_repository.dart';

class GetCgvPerOfferUseCase {
  final ContractRepository repository;

  GetCgvPerOfferUseCase({required this.repository});

  Future<Either<Failure, Uint8List>> call({required String offerName, required String lang}) async {
    return await repository.getDynamicCGV(offerName: offerName, lang: lang);
  }
}
