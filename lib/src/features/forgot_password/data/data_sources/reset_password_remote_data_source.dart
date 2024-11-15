import 'dart:convert';

import '../../../../core/api/dio_consumer.dart';
import '../../../../core/api/end_points.dart';
import '../../domain/entities/reset_password_params.dart';
import '../../domain/entities/reset_password_request_otp_params.dart';

abstract class ResetPasswordRemoteDataSource {
  Future<String> resetPasswordRequestOTP({required ResetPasswordRequestOtpParams params});
  Future<String> resetPassword({required ResetPasswordParams params});
}

class ResetPasswordRemoteDataSourceImpl implements ResetPasswordRemoteDataSource {
  final DioConsumer dioConsumer;

  ResetPasswordRemoteDataSourceImpl({required this.dioConsumer});

  @override
  Future<String> resetPassword({required ResetPasswordParams params}) async {
    final response = await dioConsumer.patch(
      EndPoints.resetPassword,
      body: params.toJson(),
      includeToken: false,
    );
    final decodedResponse = jsonDecode(response) as Map<String, dynamic>;
    return decodedResponse['message'];
  }

  @override
  Future<String> resetPasswordRequestOTP({required ResetPasswordRequestOtpParams params}) async {
    final response = await dioConsumer.post(
      EndPoints.resetPasswordOTP,
      body: params.toJson(),
      includeToken: false,
    );
    final decodedResponse = jsonDecode(response) as Map<String, dynamic>;
    return decodedResponse['message'];
  }
}
