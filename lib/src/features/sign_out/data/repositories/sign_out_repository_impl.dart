import 'package:dartz/dartz.dart';

import '../../../../core/error/exception.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/networking/network_info.dart';
import '../../../../core/utils/handlers/error_handler.dart';
import '../../../../core/utils/ressources/app_api_messages.dart';
import '../../domain/repositories/sign_out_repository.dart';
import '../data_sources/sign_out_data_source.dart';

class SignOutRepositoryImpl implements SignOutRepository {
  final NetworkInfo networkInfo;
  final SignoutRemoteDataSource remoteDataSource;

  SignOutRepositoryImpl({required this.networkInfo, required this.remoteDataSource});

  @override
  Future<Either<Failure, void>> signOut({required String token}) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.signOut(token: token);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: ErrorHandler.getErrorMessage(e)));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(
          NoInternetConnectionFailure(message: AppApiResponsesMessages.noInternetConnection));
    }
  }
}
