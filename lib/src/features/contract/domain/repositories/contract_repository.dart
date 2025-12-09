import 'dart:io';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/rasd_edit_contract_response_entity.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/rasd_generate_contract_params_entity.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/rasd_request_params_entity.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/rasd_trigger_sms_params_entity.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/retry_trigger_sms_params_entity.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/retry_trigger_sms_response_entity.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/trigger_sms_params_entity.dart';

import '../../../../core/error/failure.dart';
import '../entities/check_before_edit_contract_response_entity.dart';
import '../entities/contract_request_params_entitiy.dart';
import '../entities/edit_contract_response_entity.dart';
import '../entities/generate_contract_params_entity.dart';
import '../entities/generate_contract_response_entity.dart';

abstract class ContractRepository {
  Future<Either<Failure, Unit>> triggerSms({required TriggerSmsParamsEntity params});

  Future<Either<Failure, CheckBeforeEditContractResponseEntity>> checkBeforeEditContract({
    required ContractRequestParamsEntitiy contract,
  });

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
  });

  Future<Either<Failure, GenerateContractResponseEntity>> generateContract({
    required GenerateContractParamsEntity generateContractParams,
    required String lang,
  });

  Future<Either<Failure, RetryTriggerSmsResponseEntity>> retryTriggerSms({
    required RetryTriggerSmsParamsEntity params,
  });

  Future<Either<Failure, RasdEditContractResponseEntity>> rasdEditContract({
    required RasdEditRequestParamsEntity rasdEditRequestParamsEntity,
    required File? recto,
    required File? verso,
    required File? signature,
  });

  Future<Either<Failure, String>> rasdTriggerSms({
    required RasdTriggerSmsParamsEntity rasdTriggerSmsParamsEntity,
  });

  Future<Either<Failure, GenerateContractResponseEntity>> rasdGenerateContract({
    required RasdGenerateContractParamsEntity rasdGenerateContractParams,
    required int subscriptionId,
  });

  Future<Either<Failure, Uint8List>> getDynamicCGV(
      {required String offerName, required String lang});
}
