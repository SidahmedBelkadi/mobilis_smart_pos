import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/id_card_response_entity.dart';
import '../repositories/ocr_repository.dart';

class ProcessIdCardUseCase {
  final OcrRepository repository;

  ProcessIdCardUseCase({required this.repository});
  Future<Either<Failure, IdCardResponse>> call({required File front, required File back}) async {
    return await repository.processId(front: front, back: back);
  }
}
