import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../repositories/profile_repository.dart';

class UpdateProfileUseCase {
  final ProfileRepository repository;

  UpdateProfileUseCase({required this.repository});

  Future<Either<Failure, void>> call({
    required String employeeId,
    required String pdvCode,
    required bool isPassport,
    required File recto,
    required File? verso,
    required File commercialRgister,
    required File nif,
  }) async {
    return await repository.updatePDVInfo(
      employeeId: employeeId,
      pdvCode: pdvCode,
      isPassport: isPassport,
      recto: recto,
      verso: verso,
      commercialRgister: commercialRgister,
      nif: nif,
    );
  }
}
