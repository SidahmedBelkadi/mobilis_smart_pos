import 'dart:io';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/rasd_edit_contract_response_entity.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/rasd_generate_contract_params_entity.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/rasd_request_params_entity.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/rasd_trigger_sms_params_entity.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/retry_trigger_sms_params_entity.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/retry_trigger_sms_response_entity.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/trigger_sms_params_entity.dart';

import '../../../../core/error/exception.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/networking/network_info.dart';
import '../../../../core/utils/handlers/error_handler.dart';
import '../../../../core/utils/ressources/app_api_messages.dart';
import '../../domain/entities/check_before_edit_contract_response_entity.dart';
import '../../domain/entities/check_client_params_entity.dart';
import '../../domain/entities/contract_request_params_entitiy.dart';
import '../../domain/entities/edit_contract_response_entity.dart';
import '../../domain/entities/generate_contract_params_entity.dart';
import '../../domain/entities/generate_contract_response_entity.dart';
import '../../domain/repositories/contract_repository.dart';
import '../data_sources/contract_remote_data_source.dart';
import '../models/check_before_edit_contract_response_model.dart';

class ContractRepositoryImpl implements ContractRepository {
  final NetworkInfo networkInfo;
  final ContractRemoteDataSource remoteDataSource;

  ContractRepositoryImpl({required this.networkInfo, required this.remoteDataSource});

  /// Refusals the PDV must see as they are. Any other 400 (validator text) is an app bug.
  static const _clientRefusals = {
    'CLIENT_BLACKLISTED',
    'DOCUMENT_EXPIRED',
    'CLIENT_HAS_REACHED_SIM_LIMIT',
    'THIS_MINOR_IS_PRESUMING_TO_BE_ADULT',
    'MINOR_ACTIVATION_DISABLED',
  };

  @override
  Future<Either<Failure, Unit>> checkClient({required CheckClientParamsEntity params}) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.checkClient(params: params);
        return const Right(unit);
      } on UnprocessableEntityException catch (e) {
        if (_clientRefusals.contains(e.message)) {
          return Left(ClientRefusedFailure(message: e.message!, limit: e.body?['limit']?.toString()));
        }
        debugPrint('check-client rejected the request: ${e.message}');
        return const Left(ServerFailure(message: 'unexpectedError'));
      } on ServerException catch (e) {
        return Left(ServerFailure(message: ErrorHandler.getErrorMessage(e)));
      }
    } else {
      return const Left(NoInternetConnectionFailure(message: 'noInternetConnection'));
    }
  }

  @override
  Future<Either<Failure, CheckBeforeEditContractResponseEntity>> checkBeforeEditContract({
    required ContractRequestParamsEntitiy contract,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final CheckBeforeEditContractResponseModel checkBeforeEditContractResponseModel =
            await remoteDataSource.checkBeforeEditContract(
          contract: contract,
        );
        return Right(checkBeforeEditContractResponseModel);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: ErrorHandler.getErrorMessage(e)));
      }
    } else {
      return const Left(
          NoInternetConnectionFailure(message: AppApiResponsesMessages.noInternetConnection));
    }
  }

  @override
  Future<Either<Failure, EditContractResponseEntity>> editContract({
    required ContractRequestParamsEntitiy contract,
    required File? recto,
    required File? verso,
    required File? signature,
    required bool isPassport,
    required String pdvCode,
    required File? parentRecto,
    required File? parentVerso,
    required File? justifiatif,
    required bool? parentIsPassport,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final editContractResponseModel = await remoteDataSource.editContract(
          contract: contract,
          recto: recto,
          verso: verso,
          signature: signature,
          isPassport: isPassport,
          pdvCode: pdvCode,
          parentRecto: parentRecto,
          parentVerso: parentVerso,
          justifiatif: justifiatif,
          parentIsPassport: parentIsPassport,
        );
        return Right(editContractResponseModel);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: ErrorHandler.getErrorMessage(e)));
      }
    } else {
      return const Left(
          NoInternetConnectionFailure(message: AppApiResponsesMessages.noInternetConnection));
    }
  }

  @override
  Future<Either<Failure, GenerateContractResponseEntity>> generateContract({
    required GenerateContractParamsEntity generateContractParams,
    required String lang,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final generateContractResponseModel = await remoteDataSource.generateContrat(
            generateContractParams: generateContractParams, lang: lang);
        return Right(generateContractResponseModel);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: ErrorHandler.getErrorMessage(e)));
      }
    } else {
      return const Left(
          NoInternetConnectionFailure(message: AppApiResponsesMessages.noInternetConnection));
    }
  }

  @override
  Future<Either<Failure, Unit>> triggerSms({required TriggerSmsParamsEntity params}) async {
    if (await networkInfo.isConnected) {
      try {
        remoteDataSource.triggerSms(triggerSmsParams: params);
        return const Right(unit);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: ErrorHandler.getErrorMessage(e)));
      }
    } else {
      return const Left(
          NoInternetConnectionFailure(message: AppApiResponsesMessages.noInternetConnection));
    }
  }

  @override
  Future<Either<Failure, RetryTriggerSmsResponseEntity>> retryTriggerSms(
      {required RetryTriggerSmsParamsEntity params}) async {
    if (await networkInfo.isConnected) {
      try {
        final RetryTriggerSmsResponseEntity retryTriggerSmsResponseEntity =
            await remoteDataSource.retryTriggerSms(triggerSmsParams: params);
        return Right(retryTriggerSmsResponseEntity);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: ErrorHandler.getErrorMessage(e)));
      }
    } else {
      return const Left(
          NoInternetConnectionFailure(message: AppApiResponsesMessages.noInternetConnection));
    }
  }

  @override
  Future<Either<Failure, RasdEditContractResponseEntity>> rasdEditContract({
    required RasdEditRequestParamsEntity rasdEditRequestParamsEntity,
    required File? recto,
    required File? verso,
    required File? signature,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final rasdEditContractResponseModel = await remoteDataSource.rasdEditContract(
          rasdEditRquestParams: rasdEditRequestParamsEntity,
          recto: recto,
          verso: verso,
          signature: signature,
        );
        return Right(rasdEditContractResponseModel);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: ErrorHandler.getErrorMessage(e)));
      }
    } else {
      return const Left(
          NoInternetConnectionFailure(message: AppApiResponsesMessages.noInternetConnection));
    }
  }

  @override
  Future<Either<Failure, GenerateContractResponseEntity>> rasdGenerateContract({
    required RasdGenerateContractParamsEntity rasdGenerateContractParams,
    required int subscriptionId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final generateContractResponseModel = await remoteDataSource.rasdGenerateContrat(
            rasdGenerateContractParams: rasdGenerateContractParams, subscriptionId: subscriptionId);
        return Right(generateContractResponseModel);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: ErrorHandler.getErrorMessage(e)));
      }
    } else {
      return const Left(
          NoInternetConnectionFailure(message: AppApiResponsesMessages.noInternetConnection));
    }
  }

  @override
  Future<Either<Failure, String>> rasdTriggerSms({
    required RasdTriggerSmsParamsEntity rasdTriggerSmsParamsEntity,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final String message =
            await remoteDataSource.rasdTriggerSms(triggerSmsParams: rasdTriggerSmsParamsEntity);
        return Right(message);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: ErrorHandler.getErrorMessage(e)));
      }
    } else {
      return const Left(
          NoInternetConnectionFailure(message: AppApiResponsesMessages.noInternetConnection));
    }
  }

  @override
  Future<Either<Failure, Uint8List>> getDynamicCGV(
      {required String offerName, required String lang}) async {
    if (await networkInfo.isConnected) {
      try {
        final cgv = await remoteDataSource.getDynamicCGV(offerName: offerName, lang: lang);
        return Right(cgv);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: ErrorHandler.getErrorMessage(e)));
      }
    } else {
      return const Left(NoInternetConnectionFailure(message: 'noInternetConnection'));
    }
  }
}
