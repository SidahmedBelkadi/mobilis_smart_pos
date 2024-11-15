import 'dart:convert';

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
    final response =
        await dioConsumer.post(EndPoints.approveContract, body: params.toJson(), includeToken: false);
    final message = jsonDecode(response)["message"];
    return message;
  }
}
