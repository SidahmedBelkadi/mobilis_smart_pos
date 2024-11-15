import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';

abstract class SignOutRepository {
  Future<Either<Failure, void>> signOut({required String token});
}
