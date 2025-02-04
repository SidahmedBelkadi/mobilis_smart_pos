import 'package:dartz/dartz.dart';
import 'package:mobilis_smart_pos/src/features/home/domain/repository/home_repository.dart';

import '../../../../core/error/failure.dart';

class LoadBannersUseCase {
  final HomeRepository repository;

  LoadBannersUseCase({required this.repository});

  Future<Either<Failure, List<String>>> call() async {
    return await repository.loadBanners();
  }
}
