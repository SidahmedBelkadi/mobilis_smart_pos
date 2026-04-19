import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../data/models/notification_model.dart';
import '../repositories/notification_repository.dart';

class GetUnreadNotificationsCountUseCase {
  final NotificationRepository repository;

  GetUnreadNotificationsCountUseCase({required this.repository});

  Future<Either<Failure, NotificationResponseModel>> call() async {
    return await repository.getUnreadCount();
  }
}
