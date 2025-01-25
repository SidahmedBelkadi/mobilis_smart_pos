import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/generate_contract_response_entity.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/rasd_edit_contract_response_entity.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/rasd_generate_contract_params_entity.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/rasd_request_params_entity.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/use_cases/rasd_edit_contract_use_case.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/use_cases/rasd_generate_contract_use_case.dart';
import 'package:mobilis_smart_pos/src/features/sign_in/data/data_sources/smart_pos_local_storage.dart';

part 'rasd_contract_state.dart';

class RasdContractCubit extends Cubit<RasdContractState> {
  RasdContractCubit({
    required this.rasdEditContractUseCase,
    required this.smartPosLocalStorage,
    required this.rasdGenerateContractUseCase,
  }) : super(RasdContractInitial());

  final RasdEditContractUseCase rasdEditContractUseCase;
  final RasdGenerateContractUseCase rasdGenerateContractUseCase;
  final SmartPosLocalStorage smartPosLocalStorage;

  Future<void> rasdEditContract({
    required RasdEditRequestParamsEntity params,
    required File? recto,
    required File? verso,
    required File? signature,
  }) async {
    emit(RasdEditContractLoading());

    final failedOrRasdEditContractReponse = await rasdEditContractUseCase(
        rasdEditRequestParamsEntity: params, recto: recto, verso: verso, signature: signature);

    failedOrRasdEditContractReponse.fold(
      (error) {
        emit(RasdEditContractFailed(message: error.message));
      },
      (rasdEditContractResponseEntity) {
        emit(
          RasdEditContractSuccess(rasdEditContractResponseEntity: rasdEditContractResponseEntity),
        );
      },
    );
  }

  Future<void> rasdGenerateContract({
    required RasdGenerateContractParamsEntity params,
    required int subscriptionId,
  }) async {
    emit(RasdGenerateContractLoading());

    final failedOrRasdGenerateContract = await rasdGenerateContractUseCase(
      rasdGenerateContractParams: params,
      subscriptionId: subscriptionId,
    );

    failedOrRasdGenerateContract.fold(
      (error) {
        emit(RasdGenerateContractFailed(message: error.message));
      },
      (generateContractResponseEntity) {
        emit(
          RasdGenerateContractSuccess(
              generateContractResponseEntity: generateContractResponseEntity),
        );
      },
    );
  }
}
