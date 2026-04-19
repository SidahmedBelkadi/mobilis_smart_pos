import 'package:equatable/equatable.dart';

class Notification extends Equatable {
  final int id;
  final int notificationId;
  final int notificationPdvId;
  final bool isRead;
  final DateTime? readAt;
  final DateTime receivedAt;
  final LocalizedText title;
  final LocalizedText description;
  final String priority;
  final String type;
  final DateTime createdAt;

  const Notification({
    required this.id,
    required this.notificationId,
    required this.notificationPdvId,
    required this.isRead,
    this.readAt,
    required this.receivedAt,
    required this.title,
    required this.description,
    required this.priority,
    required this.type,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        notificationId,
        notificationPdvId,
        isRead,
        readAt,
        receivedAt,
        title,
        description,
        priority,
        type,
        createdAt,
      ];
}

class LocalizedText extends Equatable {
  final String? ar;
  final String? en;
  final String? fr;

  const LocalizedText({
    this.ar,
    this.en,
    this.fr,
  });

  String getLocalized(String languageCode) {
    switch (languageCode) {
      case 'ar':
        return ar ?? en ?? fr ?? '';
      case 'fr':
        return fr ?? en ?? ar ?? '';
      default:
        return en ?? fr ?? ar ?? '';
    }
  }

  @override
  List<Object?> get props => [ar, en, fr];
}
