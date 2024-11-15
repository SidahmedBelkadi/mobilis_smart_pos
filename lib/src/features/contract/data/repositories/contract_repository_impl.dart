import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/error/exception.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/networking/network_info.dart';
import '../../../../core/utils/handlers/error_handler.dart';
import '../../../../core/utils/ressources/app_api_messages.dart';
import '../../domain/entities/check_before_edit_contract_response_entity.dart';
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

  ContractRepositoryImpl(
      {required this.networkInfo, required this.remoteDataSource});

  @override
  Future<Either<Failure, CheckBeforeEditContractResponseEntity>>
      checkBeforeEditContract({
    required ContractRequestParamsEntitiy contract,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final CheckBeforeEditContractResponseModel
            checkBeforeEditContractResponseModel =
            await remoteDataSource.checkBeforeEditContract(
          contract: contract,
        );
        return Right(checkBeforeEditContractResponseModel);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: ErrorHandler.getErrorMessage(e)));
      }
    } else {
      return const Left(NoInternetConnectionFailure(
          message: AppApiResponsesMessages.noInternetConnection));
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
      return const Left(NoInternetConnectionFailure(
          message: AppApiResponsesMessages.noInternetConnection));
    }
  }

  @override
  Future<Either<Failure, GenerateContractResponseEntity>> generateContract({
    required GenerateContractParamsEntity generateContractParams,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final generateContractResponseModel = await remoteDataSource
            .generateContrat(generateContractParams: generateContractParams);
        return Right(generateContractResponseModel);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: ErrorHandler.getErrorMessage(e)));
      }
    } else {
      return const Left(NoInternetConnectionFailure(
          message: AppApiResponsesMessages.noInternetConnection));
    }
  }
}
