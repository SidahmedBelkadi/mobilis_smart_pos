import 'dart:convert';
import 'package:mobilis_smart_pos/src/core/api/dio_consumer.dart';
import '../../../../core/api/end_points.dart';
import '../models/notification_model.dart';

abstract class NotificationRemoteDataSource {
  Future<NotificationResponseModel> getUnreadCount();
  Future<NotificationResponseModel> getNotifications({int page = 0, int pageSize = 10});
  Future<void> markAsRead(int id);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final DioConsumer dioConsumer;

  NotificationRemoteDataSourceImpl({required this.dioConsumer});

  @override
  Future<NotificationResponseModel> getUnreadCount() async {
    final response = await dioConsumer.get(EndPoints.notificationsUnread);
    return NotificationResponseModel.fromJson(jsonDecode(response));
  }

  @override
  Future<NotificationResponseModel> getNotifications({int page = 0, int pageSize = 10}) async {
    final response = await dioConsumer.get(
      EndPoints.notificationsList,
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
      },
    );
    return NotificationResponseModel.fromJson(jsonDecode(response));
  }

  @override
  Future<void> markAsRead(int id) async {
    await dioConsumer.patch(EndPoints.notificationsMarkAsRead(id));
  }
}
