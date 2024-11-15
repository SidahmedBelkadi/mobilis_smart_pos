part of 'ocr_cubit.dart';

sealed class OcrState extends Equatable {
  const OcrState();

  @override
  List<Object> get props => [];
}

final class OcrInitial extends OcrState {}

// ============= ID CARD =============== //

final class ProcessIDCardSuccess extends OcrState {
  final IdCardResponse idCardResponse;

  const ProcessIDCardSuccess({required this.idCardResponse});
  @override
  List<Object> get props => [idCardResponse];
}

final class ProcessIDCardFailure extends OcrState {}

final class ProcessIDCardLoading extends OcrState {}

// ============= PASSPORT =============== //

final class ProcessPassortSuccess extends OcrState {
  final PassportResponse passportResponse;

  const ProcessPassortSuccess({required this.passportResponse});
  @override
  List<Object> get props => [passportResponse];
}

final class ProcessPassportFailure extends OcrState {}

final class ProcessPassportLoading extends OcrState {}
