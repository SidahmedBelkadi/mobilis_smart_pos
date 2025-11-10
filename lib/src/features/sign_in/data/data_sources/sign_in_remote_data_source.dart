import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:http_parser/http_parser.dart';

import '../../../../core/api/dio_consumer.dart';
import '../../../../core/api/end_points.dart';
import '../../domain/entities/sign_in_approve_contract_params.dart';
import '../models/sign_in_otp_response_model.dart';
import '../models/sign_in_response_model.dart';
import '../../domain/entities/sign_in_otp_request_params.dart';
import '../../domain/entities/sign_in_request_params.dart';

abstract class SignInRemoteDataSource {
  Future<SignInResponseModel> signIn({required SignInRequestParams params});
  Future<SignInOTPResponseModel> verifyOTP({required SignInOTPRequestParams params});
  Future<String> approveContract({required SignInApproveContractParams params});
  Future<Uint8List> getPdvContract();
  Future<void> signAndApproveContract({required File signatureFile});
}

class SignInRemoteDataSourceImpl implements SignInRemoteDataSource {
  final DioConsumer dioConsumer;

  SignInRemoteDataSourceImpl({required this.dioConsumer});

  @override
  Future<SignInResponseModel> signIn({required SignInRequestParams params}) async {
    final result =
        await dioConsumer.post(EndPoints.signIn, body: params.toJson(), includeToken: false);
    return SignInResponseModel.fromJson(jsonDecode(result));
  }

  @override
  Future<SignInOTPResponseModel> verifyOTP({required SignInOTPRequestParams params}) async {
    final result =
        await dioConsumer.post(EndPoints.verifyOTP, body: params.toJson(), includeToken: false);
    return SignInOTPResponseModel.fromJson(jsonDecode(result));
  }

  @override
  Future<String> approveContract({required SignInApproveContractParams params}) async {
    final response = await dioConsumer.post(EndPoints.approveContract,
        body: params.toJson(), includeToken: false);
    final message = jsonDecode(response)["message"];
    return message;
  }

  @override
  Future<Uint8List> getPdvContract() async {
    final response = await dioConsumer.get(
      EndPoints.getPdvContract,
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

  @override
  Future<void> signAndApproveContract({required File signatureFile}) async {
    final formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(signatureFile.path,
          filename: 'signature.png', contentType: MediaType('image', 'png')),
    });
    await dioConsumer.post(EndPoints.signAndApprovePDVContract,
        body: formData, formDataIsEnabled: true);
  }
}
