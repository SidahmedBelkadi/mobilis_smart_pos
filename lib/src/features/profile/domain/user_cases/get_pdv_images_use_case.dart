import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../repositories/profile_repository.dart';

class GetPdvImagesUseCase {
  final ProfileRepository repository;

  GetPdvImagesUseCase({required this.repository});

  Future<Either<Failure, List>> call({required String pdvCode}) async {
    return await repository.getPdvImages(pdvCode: pdvCode);
  }
}
