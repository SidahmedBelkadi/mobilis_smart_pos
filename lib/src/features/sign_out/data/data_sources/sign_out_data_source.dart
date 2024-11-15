import '../../../../core/api/dio_consumer.dart';
import '../../../../core/api/end_points.dart';

abstract class SignoutRemoteDataSource {
  Future<void> signOut({required String token});
}

class SignoutRemoteDataSourceImpl implements SignoutRemoteDataSource {
  final DioConsumer dioConsumer;

  SignoutRemoteDataSourceImpl({required this.dioConsumer});

  @override
  Future<void> signOut({required String token}) async {
    await dioConsumer.post(
      EndPoints.signOut,
      body: {'token': token},
    );
  }
}
