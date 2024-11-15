import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/profile_response_entity.dart';

abstract class ProfileRepository {
  Future<Either<Failure, ProfileResponseEntity>> getPDVInfo(
      {required int pdvID});

  Future<Either<Failure, void>> updatePDVInfo({
    required String employeeId,
    required String pdvCode,
    required bool isPassport,
    required File recto,
    required File? verso,
    required File commercialRgister,
    required File nif,
  });

  Future<Either<Failure, List>> getPdvImages({required String pdvCode});
}
