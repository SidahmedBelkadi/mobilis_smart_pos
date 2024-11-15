import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../../../core/api/dio_consumer.dart';
import '../../../../core/api/end_points.dart';
import '../../domain/entities/contract_request_params_entitiy.dart';
import '../../domain/entities/generate_contract_params_entity.dart';
import '../models/check_before_edit_contract_response_model.dart';
import '../models/edit_contract_response_model.dart';
import '../models/generate_contract_response_model.dart';

abstract class ContractRemoteDataSource {
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
  });
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
        isPassport ? 'pr_passport' : 'pr_card_id_recto':
            await MultipartFile.fromFile(
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
  }) async {
    final Map<String, dynamic> body = {
      "msisdn": generateContractParams.msisdn,
      "CC_code": generateContractParams.contractCode,
      "message": generateContractParams.dsaMessage,
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
}
