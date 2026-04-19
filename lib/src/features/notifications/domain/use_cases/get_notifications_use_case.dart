import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../data/models/notification_model.dart';
import '../repositories/notification_repository.dart';

class GetNotificationsUseCase {
  final NotificationRepository repository;

  GetNotificationsUseCase({required this.repository});

  Future<Either<Failure, NotificationResponseModel>> call({int page = 0, int pageSize = 10}) async {
    return await repository.getNotifications(page: page, pageSize: pageSize);
  }
}
