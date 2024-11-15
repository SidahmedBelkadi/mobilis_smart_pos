import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/id_card_response_entity.dart';
import '../../domain/entities/passport_response_entity.dart';
import '../../domain/use_cases/process_id_card_use_case.dart';
import '../../domain/use_cases/process_passport_use_case.dart';

part 'ocr_state.dart';

class OcrCubit extends Cubit<OcrState> {
  final ProcessIdCardUseCase idCardUseCase;
  final ProcessPassportUseCase passportUseCase;
  OcrCubit({
    required this.idCardUseCase,
    required this.passportUseCase,
  }) : super(OcrInitial());

  Future<void> processId({
    required File front,
    required File back,
  }) async {
    emit(ProcessIDCardLoading());

    final failureOrIdCardResponse = await idCardUseCase(front: front, back: back);

    failureOrIdCardResponse.fold(
      (error) {
        emit(ProcessIDCardFailure());
      },
      (idCardResponse) {
        emit(ProcessIDCardSuccess(idCardResponse: idCardResponse));
      },
    );
  }

  Future<void> processPassport({
    required File front,
  }) async {
    emit(ProcessPassportLoading());
    final failureOrPassportResponse = await passportUseCase(front: front);

    failureOrPassportResponse.fold(
      (error) {
        emit(ProcessPassportFailure());
      },
      (passportResponse) {
        emit(ProcessPassortSuccess(passportResponse: passportResponse));
      },
    );
  }
}
