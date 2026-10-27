import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../../core/error/failure.dart';
import '../../../domain/entities/check_client_params_entity.dart';
import '../../../domain/use_cases/check_client_use_case.dart';

part 'check_client_state.dart';

/// Checks right after the ID scan that the client can be activated, so the PDV
/// stops before scanning a SIM or asking for a signature.
class CheckClientCubit extends Cubit<CheckClientState> {
  final CheckClientUseCase checkClientUseCase;

  CheckClientCubit({required this.checkClientUseCase}) : super(CheckClientInitial());

  Future<void> checkClient(CheckClientParamsEntity params) async {
    emit(CheckClientLoading());
    final result = await checkClientUseCase(params: params);
    result.fold(
      (failure) => emit(failure is ClientRefusedFailure
          ? CheckClientRefused(message: failure.message, limit: failure.limit)
          : CheckClientFailed(message: failure.message)),
      (_) => emit(CheckClientEligible()),
    );
  }
}
