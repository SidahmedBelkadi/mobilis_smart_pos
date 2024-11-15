import 'dart:io';

import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/passport_response_entity.dart';
import '../repositories/ocr_repository.dart';

class ProcessPassportUseCase {
  final OcrRepository repository;

  ProcessPassportUseCase({required this.repository});
  Future<Either<Failure, PassportResponse>> call({required File front}) async {
    return await repository.processPassport(front: front);
  }
}
