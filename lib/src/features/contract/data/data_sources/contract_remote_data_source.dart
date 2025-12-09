import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mobilis_smart_pos/src/features/contract/data/models/rasd_edit_contract_response_model.dart';
import 'package:mobilis_smart_pos/src/features/contract/data/models/retry_trigger_sms_response_model.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/rasd_generate_contract_params_entity.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/rasd_request_params_entity.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/rasd_trigger_sms_params_entity.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/retry_trigger_sms_params_entity.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/trigger_sms_params_entity.dart';
import 'package:mobilis_smart_pos/src/features/sign_in/data/data_sources/smart_pos_local_storage.dart';

import '../../../../core/api/dio_consumer.dart';
import '../../../../core/api/end_points.dart';
import '../../domain/entities/contract_request_params_entitiy.dart';
import '../../domain/entities/generate_contract_params_entity.dart';
import '../models/check_before_edit_contract_response_model.dart';
import '../models/edit_contract_response_model.dart';
import '../models/generate_contract_response_model.dart';
import '../../../../dependency_injection/injection_container.dart' as di;

abstract class ContractRemoteDataSource {
  Future<void> triggerSms({required TriggerSmsParamsEntity triggerSmsParams});

  Future<RetryTriggerSmsResponseModel> retryTriggerSms({
    required RetryTriggerSmsParamsEntity triggerSmsParams,
  });

  Future<CheckBeforeEditContractResponseModel> checkBeforeEditContract({
    required ContractRequestParamsEntitiy contract,
  });

  Future<EditContractResponseModel> editContract({
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

  Future<GenerateContractResponseModel> generateContrat({
    required GenerateContractParamsEntity generateContractParams,
    required String lang,
  });

  Future<RasdEditContractResponseModel> rasdEditContract({
    required RasdEditRequestParamsEntity rasdEditRquestParams,
    required File? recto,
    required File? verso,
    required File? signature,
  });

  Future<String> rasdTriggerSms({
    required RasdTriggerSmsParamsEntity triggerSmsParams,
  });

  Future<GenerateContractResponseModel> rasdGenerateContrat({
    required RasdGenerateContractParamsEntity rasdGenerateContractParams,
    required int subscriptionId,
  });

  Future<Uint8List> getDynamicCGV({required String offerName, required String lang});
}

class ContractRemoteDataSourceImpl implements ContractRemoteDataSource {
  final DioConsumer dioConsumer;

  ContractRemoteDataSourceImpl({required this.dioConsumer});

  @override
  Future<CheckBeforeEditContractResponseModel> checkBeforeEditContract({
    required ContractRequestParamsEntitiy contract,
  }) async {
    final response = await dioConsumer.post(
      EndPoints.checkBeforeEditContract,
      body: contract.toJson(),
    );

    return CheckBeforeEditContractResponseModel.fromJson(jsonDecode(response));
  }

  @override
  Future<EditContractResponseModel> editContract({
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
    final formData = FormData.fromMap({
      if (recto != null)
        isPassport ? 'passport' : 'card_id_recto': await MultipartFile.fromFile(
          recto.path,
          filename: 'recto.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      if (verso != null)
        'card_id_verso': await MultipartFile.fromFile(
          verso.path,
          filename: 'verso.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      if (signature != null)
        'signature': await MultipartFile.fromFile(
          signature.path,
          filename: 'signature.png',
          contentType: MediaType('image', 'png'),
        ),
      if (parentRecto != null)
        isPassport ? 'pr_passport' : 'pr_card_id_recto': await MultipartFile.fromFile(
          parentRecto.path,
          filename: 'pr_card_id_recto.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      if (parentVerso != null)
        'pr_card_id_verso': await MultipartFile.fromFile(
          parentVerso.path,
          filename: 'pr_card_id_verso.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      if (justifiatif != null)
        'pr_justification': await MultipartFile.fromFile(
          justifiatif.path,
          filename: 'pr_justification.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
    });

    final uploadResponse = await dioConsumer.put(
      "${EndPoints.uploadClient}/$pdvCode",
      body: formData,
      formDataIsEnabled: true,
    );

    final folderUrl = jsonDecode(uploadResponse)['folderUrl'];

    final response = await dioConsumer.post(
      EndPoints.editContract,
      body: contract.copyWith(folderUrl: folderUrl).toJson(),
    );

    return EditContractResponseModel.fromJson(json: jsonDecode(response));
  }

  @override
  Future<GenerateContractResponseModel> generateContrat({
    required GenerateContractParamsEntity generateContractParams,
    required String lang,
  }) async {
    final Map<String, dynamic> body = {
      "msisdn": generateContractParams.msisdn,
      "CC_code": generateContractParams.contractCode,
      "message": generateContractParams.dsaMessage,
      "lang": lang,
    };
    final clientId = generateContractParams.clientId;
    final invoiceId = generateContractParams.invoiceId;
    final subId = generateContractParams.subsId;
    final response = await dioConsumer.post(
      "${EndPoints.generateContrcat}/$clientId/$invoiceId/$subId",
      body: body,
    );

    return GenerateContractResponseModel.fromJson(json: jsonDecode(response));
  }

  @override
  Future<void> triggerSms({
    required TriggerSmsParamsEntity triggerSmsParams,
  }) async {
    await dioConsumer.post(EndPoints.triggerSms, body: triggerSmsParams.toJson());
  }

  @override
  Future<RetryTriggerSmsResponseModel> retryTriggerSms({
    required RetryTriggerSmsParamsEntity triggerSmsParams,
  }) async {
    final response =
        await dioConsumer.post(EndPoints.retryTriggerSms, body: triggerSmsParams.toJson());
    return RetryTriggerSmsResponseModel.fromJson(json: jsonDecode(response));
  }

  @override
  Future<RasdEditContractResponseModel> rasdEditContract({
    required RasdEditRequestParamsEntity rasdEditRquestParams,
    required File? recto,
    required File? verso,
    required File? signature,
  }) async {
    final formData = FormData.fromMap({
      if (recto != null)
        'card_id_recto': await MultipartFile.fromFile(
          recto.path,
          filename: 'recto.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      if (verso != null)
        'card_id_verso': await MultipartFile.fromFile(
          verso.path,
          filename: 'verso.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      if (signature != null)
        'signature': await MultipartFile.fromFile(
          signature.path,
          filename: 'signature.png',
          contentType: MediaType('image', 'png'),
        ),
    });

    final pdvCode = di.serviceLocator<SmartPosLocalStorage>().getSavedLoginCredentials()!.pdvCode!;

    final uploadResponse = await dioConsumer.put(
      "${EndPoints.uploadClientRasd}/$pdvCode",
      body: formData,
      formDataIsEnabled: true,
    );

    final folderUrl = jsonDecode(uploadResponse)['folderUrl'];

    final response = await dioConsumer.post(
      EndPoints.rasdEditContract,
      body: rasdEditRquestParams.copyWith(folderFiles: folderUrl).toJson(),
    );

    return RasdEditContractResponseModel.fromJson(json: jsonDecode(response));
  }

  @override
  Future<GenerateContractResponseModel> rasdGenerateContrat({
    required RasdGenerateContractParamsEntity rasdGenerateContractParams,
    required int subscriptionId,
  }) async {
    final response = await dioConsumer.post(
      "${EndPoints.rasdGenerateContrcat}/$subscriptionId",
      body: rasdGenerateContractParams.toJson(),
    );

    return GenerateContractResponseModel.fromJson(json: jsonDecode(response));
  }

  @override
  Future<String> rasdTriggerSms({
    required RasdTriggerSmsParamsEntity triggerSmsParams,
  }) async {
    final response =
        await dioConsumer.post(EndPoints.rasdTriggerSms, body: triggerSmsParams.toJson());
    return jsonDecode(response)['message'];
  }

  @override
  Future<Uint8List> getDynamicCGV({required String offerName, required String lang}) async {
    final response = await dioConsumer.get(
      "${EndPoints.getDynamicCGV}/$offerName/$lang",
      responseType: ResponseType.bytes,
    );

    if (response is List<int>) {
      debugPrint("PDF header: ${utf8.decode(response.take(10).toList(), allowMalformed: true)}");
      return Uint8List.fromList(response);
    }

    if (response is String) {
      if (!response.startsWith('%PDF')) {
        try {
          final decoded = base64Decode(response);
          debugPrint("PDF decoded from Base64 (length: ${decoded.length})");
          return decoded;
        } catch (_) {
          return Uint8List.fromList(response.codeUnits);
        }
      }
      return Uint8List.fromList(response.codeUnits);
    }

    throw Exception("Unexpected response type: ${response.runtimeType}");
  }
}
