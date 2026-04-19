import 'package:dartz/dartz.dart';
import 'package:mobilis_smart_pos/src/features/notifications/data/models/notification_model.dart';
import '../../../../core/error/failure.dart';

abstract class NotificationRepository {
  Future<Either<Failure, NotificationResponseModel>> getUnreadCount();
  Future<Either<Failure, NotificationResponseModel>> getNotifications({int page = 0, int pageSize = 10});
  Future<Either<Failure, void>> markAsRead(int id);
}
