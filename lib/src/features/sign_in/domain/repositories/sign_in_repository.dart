import 'package:dartz/dartz.dart';
import 'package:mobilis_smart_pos/src/features/sign_in/domain/entities/sign_in_approve_contract_params.dart';

import '../../../../core/error/failure.dart';
import '../entities/sign_in_otp_request_params.dart';
import '../entities/sign_in_otp_response_entity.dart';
import '../entities/sign_in_request_params.dart';
import '../entities/sign_in_response.dart';

abstract class SignInRepository {
  Future<Either<Failure, SignInResponseEntity>> signIn({required SignInRequestParams params});
  Future<Either<Failure, SignInOTPResponseEntity>> verifyOTP({
    required SignInOTPRequestParams params,
  });
  Future<Either<Failure, String>> approveContract({required SignInApproveContractParams params});
}
