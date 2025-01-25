import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/rasd_trigger_sms_params_entity.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/use_cases/rasd_trigger_sms_use_case.dart';
import 'package:mobilis_smart_pos/src/features/sign_in/data/data_sources/smart_pos_local_storage.dart';

part 'rasd_sms_state.dart';

class RasdSmsCubit extends Cubit<RasdSmsState> {
  RasdSmsCubit({
    required this.smartPosLocalStorage,
    required this.rasdTrigggerSmsUseCase,
  }) : super(RasdSmsInitial());

  final SmartPosLocalStorage smartPosLocalStorage;
  final RasdTrigggerSmsUseCase rasdTrigggerSmsUseCase;

  Future<void> rasdTriggerSms({
    required RasdTriggerSmsParamsEntity rasdTriggerSmsParamsEntity,
  }) async {
    emit(RasdTriggerSmsLoading());

    final failureOrTriggerSmsResponse = await rasdTrigggerSmsUseCase(
      trigggerSmsParams: rasdTriggerSmsParamsEntity,
    );

    failureOrTriggerSmsResponse.fold(
      (error) {
        emit(RasdTriggerSmsFailed(message: error.message));
      },
      (r) {
        // emit(RasdTriggerSmsSuccess());
      },
    );
  }
}
