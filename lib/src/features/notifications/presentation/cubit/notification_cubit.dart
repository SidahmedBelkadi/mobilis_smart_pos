import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/notification_model.dart';
import '../../domain/use_cases/get_notifications_use_case.dart';
import '../../domain/use_cases/get_unread_count_use_case.dart';
import '../../domain/use_cases/mark_as_read_use_case.dart';

part 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final GetNotificationsUseCase getNotificationsUseCase;
  final MarkAsReadUseCase markAsReadUseCase;
  final GetUnreadNotificationsCountUseCase getUnreadNotificationsCountUseCase;

  int _currentPage = 0;
  final int _pageSize = 10;
  bool _hasReachedMax = false;

  NotificationCubit({
    required this.getNotificationsUseCase,
    required this.markAsReadUseCase,
    required this.getUnreadNotificationsCountUseCase,
  }) : super(NotificationInitial());

  Future<void> getNotifications({bool isLoadMore = false, bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 0;
      _hasReachedMax = false;
    }

    if (isLoadMore) {
      if (_hasReachedMax || state is NotificationLoadingMore) return;
      final currentNotifications = (state as NotificationLoaded).notifications;
      emit(NotificationLoadingMore(notifications: currentNotifications));
    } else if (!isRefresh) {
      emit(NotificationLoading());
    }

    final failureOrNotifications = await getNotificationsUseCase(
      page: _currentPage,
      pageSize: _pageSize,
    );

    failureOrNotifications.fold(
      (failure) => emit(NotificationError(message: failure.message)),
      (newNotificationsRes) {
        if (isLoadMore && state is NotificationLoadingMore) {
          final oldRows = (state as NotificationLoadingMore).notifications.rows;
          final combinedRows = List<NotificationModel>.from(oldRows)..addAll(newNotificationsRes.rows);
          
          _hasReachedMax = newNotificationsRes.rows.length < _pageSize;
          _currentPage++;

          emit(NotificationLoaded(
            notifications: NotificationResponseModel(
              rows: combinedRows,
              count: newNotificationsRes.count,
              unreadCount: newNotificationsRes.unreadCount,
            ),
            hasMore: !_hasReachedMax,
          ));
        } else {
          _hasReachedMax = newNotificationsRes.rows.length < _pageSize;
          _currentPage = 1;
          emit(NotificationLoaded(
            notifications: newNotificationsRes,
            hasMore: !_hasReachedMax,
          ));
        }
      },
    );
  }

  Future<void> markAsRead(int id) async {
    final currentState = state;
    if (currentState is! NotificationLoaded) return;

    // Check if it's already read locally to avoid redundant work
    final notificationIndex = currentState.notifications.rows.indexWhere((n) => n.notificationPdvId == id);
    if (notificationIndex == -1 || currentState.notifications.rows[notificationIndex].isRead) return;

    // Shown as read as soon as it is opened, without waiting for the server
    final updatedRows = List<NotificationModel>.from(currentState.notifications.rows);
    final oldNotification = updatedRows[notificationIndex];

    updatedRows[notificationIndex] = NotificationModel(
      id: oldNotification.id,
      notificationId: oldNotification.notificationId,
      notificationPdvId: oldNotification.notificationPdvId,
      isRead: true, // Marker as read
      readAt: DateTime.now(),
      receivedAt: oldNotification.receivedAt,
      title: oldNotification.title,
      description: oldNotification.description,
      priority: oldNotification.priority,
      type: oldNotification.type,
      createdAt: oldNotification.createdAt,
    );

    final newUnreadCount = (currentState.notifications.unreadCount ?? 0) > 0
        ? (currentState.notifications.unreadCount! - 1)
        : 0;

    emit(NotificationLoaded(
      notifications: NotificationResponseModel(
        rows: updatedRows,
        count: currentState.notifications.count,
        unreadCount: newUnreadCount,
      ),
      hasMore: currentState.hasMore,
    ));

    final result = await markAsReadUseCase(id);

    result.fold(
      (failure) {
        // Not saved on the server: show it unread again, so it is marked at the next opening
        final latestState = state;
        if (latestState is! NotificationLoaded) return;
        final rows = List<NotificationModel>.from(latestState.notifications.rows);
        final index = rows.indexWhere((n) => n.notificationPdvId == id);
        if (index == -1) return;
        rows[index] = oldNotification;
        emit(NotificationLoaded(
          notifications: NotificationResponseModel(
            rows: rows,
            count: latestState.notifications.count,
            unreadCount: (latestState.notifications.unreadCount ?? 0) + 1,
          ),
          hasMore: latestState.hasMore,
        ));
      },
      (_) {
        // Fetch real count from server to remain perfectly synced
        getUnreadNotificationsCountUseCase().then((result) {
          result.fold(
            (failure) => null,
            (response) {
              final latestState = state;
              if (latestState is NotificationLoaded) {
                emit(NotificationLoaded(
                  notifications: NotificationResponseModel(
                    rows: latestState.notifications.rows,
                    count: latestState.notifications.count,
                    unreadCount: response.unreadCount ?? response.count,
                  ),
                  hasMore: latestState.hasMore,
                ));
              }
            },
          );
        });
      },
    );
  }
}
