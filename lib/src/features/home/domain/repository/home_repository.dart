import 'package:dartz/dartz.dart';
import 'package:mobilis_smart_pos/src/core/error/failure.dart';

abstract class HomeRepository {
  Future<Either<Failure, List<String>>> loadBanners();
}
