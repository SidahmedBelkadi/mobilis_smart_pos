import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/id_card_response_entity.dart';
import '../entities/passport_response_entity.dart';

abstract class OcrRepository {
  Future<Either<Failure, IdCardResponse>> processId({required File front, required File back});
  Future<Either<Failure, PassportResponse>> processPassport({required File front});
}
