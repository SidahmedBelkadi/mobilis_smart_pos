import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mobilis_smart_pos/src/features/invoices/domain/entities/retry_activation_response_entity.dart';
import 'package:mobilis_smart_pos/src/features/invoices/domain/use_cases/retry_activation_use_case.dart';

part 'retry_activation_state.dart';

class RetryActivationCubit extends Cubit<RetryActivationState> {
  final RetryActivationUseCase useCase;
  RetryActivationCubit({required this.useCase}) : super(RetryActivationInitial());

  Future<void> retryActivation({required String id}) async {
    emit(RetryActivationLoading(id: int.parse(id)));

    final failureOrRetryActivationResponseEntity = await useCase(id: id);
    failureOrRetryActivationResponseEntity.fold(
      (error) {
        emit(RetryActivationFailure(message: error.message));
      },
      (responseEntity) {
        emit(RetryActivationSuccess(responseEntity: responseEntity));
      },
    );
  }
}
