import '../../domain/entities/notification.dart';

class NotificationModel extends Notification {
  const NotificationModel({
    required super.id,
    required super.notificationId,
    required super.notificationPdvId,
    required super.isRead,
    super.readAt,
    required super.receivedAt,
    required super.title,
    required super.description,
    required super.priority,
    required super.type,
    required super.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      notificationId: json['notification_id'],
      notificationPdvId: json['notification_pdv_id'],
      isRead: json['is_read'],
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']).toLocal() : null,
      receivedAt: DateTime.parse(json['received_at']).toLocal(),
      title: LocalizedTextModel.fromJson(json['title']),
      description: LocalizedTextModel.fromJson(json['description']),
      priority: json['priority'],
      type: json['type'],
      createdAt: DateTime.parse(json['created_at']).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'notification_id': notificationId,
      'notification_pdv_id': notificationPdvId,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'received_at': receivedAt.toIso8601String(),
      'title': (title as LocalizedTextModel).toJson(),
      'description': (description as LocalizedTextModel).toJson(),
      'priority': priority,
      'type': type,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class LocalizedTextModel extends LocalizedText {
  const LocalizedTextModel({
    super.ar,
    super.en,
    super.fr,
  });

  factory LocalizedTextModel.fromJson(Map<String, dynamic> json) {
    return LocalizedTextModel(
      ar: json['ar'],
      en: json['en'],
      fr: json['fr'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ar': ar,
      'en': en,
      'fr': fr,
    };
  }
}

class NotificationResponseModel {
  final List<NotificationModel> rows;
  final int count;
  final int? unreadCount;

  NotificationResponseModel({
    this.rows = const [],
    required this.count,
    this.unreadCount,
  });

  factory NotificationResponseModel.fromJson(Map<String, dynamic> json) {
    final rowsJson = json['rows'];
    return NotificationResponseModel(
      rows: rowsJson is List
          ? rowsJson.map((i) => NotificationModel.fromJson(i)).toList()
          : const [],
      count: json['count'] ?? 0,
      unreadCount: json['unread_count'],
    );
  }
}
