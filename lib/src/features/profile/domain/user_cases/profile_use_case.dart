import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/profile_response_entity.dart';
import '../repositories/profile_repository.dart';

class GetProfileInfoUseCase {
  final ProfileRepository repository;

  GetProfileInfoUseCase({required this.repository});

  Future<Either<Failure, ProfileResponseEntity>> call({required int pdvID}) async {
    return await repository.getPDVInfo(pdvID: pdvID);
  }
}
