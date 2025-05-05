import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../sign_in/data/data_sources/smart_pos_local_storage.dart';
import '../../domain/entities/contract_request_params_entitiy.dart';
import '../../domain/entities/edit_contract_response_entity.dart';
import '../../domain/entities/generate_contract_params_entity.dart';
import '../../domain/entities/generate_contract_response_entity.dart';
import '../../domain/use_cases/check_before_edit_contract_use_case.dart';
import '../../domain/use_cases/edit_contract_use_case.dart';
import '../../domain/use_cases/generate_contract_use_case.dart';

part 'contract_state.dart';

class ContractCubit extends Cubit<ContractState> {
  final CheckBeforeEditContractUseCase checkBeforeEditContractUseCase;
  final EditContractUseCase editContractUseCase;
  final GenerateContractUseCase generateContractUseCase;
  final SmartPosLocalStorage authenticationLocalDataSource;

  ContractCubit({
    required this.checkBeforeEditContractUseCase,
    required this.editContractUseCase,
    required this.generateContractUseCase,
    required this.authenticationLocalDataSource,
  }) : super(ContractInitial());

  Future<void> checkBeforeEditContract({
    required ContractRequestParamsEntitiy contract,
  }) async {
    emit(CheckBeforeEditContractLoading());

    final failureOrCheckBeforeEditResponseEntity =
        await checkBeforeEditContractUseCase(contract: contract);

    failureOrCheckBeforeEditResponseEntity.fold((error) {
      emit(CheckBeforeEditContractFailed(message: error.message));
    }, (checkBeforeEditResponseEntity) async {
      emit(CheckBeforeEditContractSuccess(
          formattedStringWithoutSpaces:
              checkBeforeEditResponseEntity.formattedStringWithoutSpaces));
    });
  }

  Future<void> editContract({
    required ContractRequestParamsEntitiy contract,
    required File? recto,
    required File? verso,
    required bool isPassport,
    required File? signature,
    required File? parentRecto,
    required File? parentVerso,
    required File? justifiatif,
    required bool? parentIsPassport,
  }) async {
    emit(EditContractLoading());

    final savedLoginCredentials = authenticationLocalDataSource.getSavedLoginCredentials();
    if (savedLoginCredentials != null) {
      if (savedLoginCredentials.pdvCode != null) {
        final failureOrEditContractResponseEntity = await editContractUseCase(
            contract: contract,
            recto: recto,
            verso: verso,
            signature: signature,
            isPassport: isPassport,
            pdvCode: savedLoginCredentials.pdvCode!,
            parentRecto: parentRecto,
            parentVerso: parentVerso,
            justifiatif: justifiatif,
            parentIsPassport: parentIsPassport);

        failureOrEditContractResponseEntity.fold((error) {
          emit(EditContractFailed(message: error.message));
        }, (editContractResponseEntity) async {
          emit(EditContractSuccess(editContractResponseEntity: editContractResponseEntity));
        });
      } else {
        emit(const EditContractFailed(
          message: "Erreur interne, veuillez réessayer ultérieurement.",
        ));
      }
    } else {
      emit(const EditContractFailed(
        message: "Erreur interne, veuillez réessayer ultérieurement.",
      ));
    }
  }

  Future<void> generateContract({
    required GenerateContractParamsEntity params,
  }) async {
    emit(GenerateContractLoading());

    final failureOrGenerateContractResponseEntity =
        await generateContractUseCase(generateContractParams: params);

    failureOrGenerateContractResponseEntity.fold((error) {
      emit(GenerateContractFailed(message: error.message));
    }, (generateContractResponseEntity) async {
      emit(GenerateContractSuccess(generateContractResponseEntity: generateContractResponseEntity));
    });
  }
}
