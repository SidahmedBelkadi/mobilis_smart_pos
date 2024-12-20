import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/trigger_sms_params_entity.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/use_cases/trigger_sms_use_case.dart';

part 'sms_state.dart';

class SmsCubit extends Cubit<SmsState> {
  final TrigggerSmsUseCase useCase;
  SmsCubit({required this.useCase}) : super(SmsInitial());

  Future<void> triggerSms({required TriggerSmsParamsEntity smsParams}) async {
    emit(TriggerSmsLoading());

    final failureOrUnit = await useCase(trigggerSmsParams: smsParams);
    failureOrUnit.fold(
      (error) {
        emit(TriggerSmsFailure(message: error.message));
      },
      (_) {
        emit(TriggerSmsSuccess());
      },
    );
  }
}
