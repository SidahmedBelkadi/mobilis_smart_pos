part of 'notification_cubit.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationLoadingMore extends NotificationState {
  final NotificationResponseModel notifications;

  const NotificationLoadingMore({required this.notifications});

  @override
  List<Object?> get props => [notifications];
}

class NotificationLoaded extends NotificationState {
  final NotificationResponseModel notifications;
  final bool hasMore;

  const NotificationLoaded({required this.notifications, this.hasMore = false});

  @override
  List<Object?> get props => [notifications, hasMore];
}

class NotificationError extends NotificationState {
  final String message;

  const NotificationError({required this.message});

  @override
  List<Object?> get props => [message];
}
