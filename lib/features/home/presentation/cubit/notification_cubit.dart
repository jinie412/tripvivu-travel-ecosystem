import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/notification_entity.dart';
import 'package:travel_advisor_mobile/features/home/domain/usecases/notification_usecases.dart';
import 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final GetNotificationsUseCase _getNotifications;
  final GetNotificationDetailUseCase _getNotificationDetail;
  final MarkAllNotificationsAsReadUseCase _markAllAsRead;
  final MarkNotificationAsReadUseCase _markAsRead;
  final RespondToItineraryShareUseCase _respondToItineraryShare;
  final Set<String> _locallyReadIds = <String>{};

  NotificationCubit({
    required GetNotificationsUseCase getNotifications,
    required GetNotificationDetailUseCase getNotificationDetail,
    required MarkAllNotificationsAsReadUseCase markAllAsRead,
    required MarkNotificationAsReadUseCase markAsRead,
    required RespondToItineraryShareUseCase respondToItineraryShare,
  }) : _getNotifications = getNotifications,
       _getNotificationDetail = getNotificationDetail,
       _markAllAsRead = markAllAsRead,
       _markAsRead = markAsRead,
       _respondToItineraryShare = respondToItineraryShare,
       super(const NotificationInitial());

  Future<void> loadNotifications({bool silent = false}) async {
    if (!silent) {
      emit(const NotificationLoading());
    }
    try {
      final notifications = _applyLocalReadState(await _getNotifications());
      emit(NotificationLoaded(notifications));
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> loadNotificationDetail(String id) async {
    emit(const NotificationLoading());
    try {
      final notification = await _getNotificationDetail(id);
      emit(NotificationDetailLoaded(notification));
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  void markNotificationAsReadLocally(String id) {
    final currentState = state;
    if (currentState is! NotificationLoaded) return;
    _locallyReadIds.add(id);

    final notifications = currentState.notifications.map((notification) {
      if (notification.id != id) return notification;
      return notification.copyWith(isUnread: false);
    }).toList();

    emit(NotificationLoaded(notifications));
  }

  Future<NotificationEntity?> markNotificationAsRead(String id) async {
    final currentState = state;
    if (currentState is! NotificationLoaded) return null;

    _locallyReadIds.add(id);
    final previousNotifications = currentState.notifications;
    final optimisticNotifications = previousNotifications.map((notification) {
      if (notification.id != id) return notification;
      return notification.copyWith(isUnread: false);
    }).toList();

    emit(NotificationLoaded(optimisticNotifications));

    try {
      final updatedNotification = await _markAsRead(id);
      final syncedNotifications = optimisticNotifications.map((notification) {
        if (notification.id != id) return notification;
        return updatedNotification.copyWith(isUnread: false);
      }).toList();
      emit(NotificationLoaded(syncedNotifications));
      return updatedNotification.copyWith(isUnread: false);
    } catch (_) {
      _locallyReadIds.remove(id);
      emit(NotificationLoaded(previousNotifications));
      rethrow;
    }
  }

  Future<void> markAllAsRead() async {
    final currentState = state;
    if (currentState is! NotificationLoaded) return;

    _locallyReadIds.addAll(
      currentState.notifications.map((notification) => notification.id),
    );
    final notifications = currentState.notifications
        .map((notification) => notification.copyWith(isUnread: false))
        .toList();
    emit(NotificationLoaded(notifications));

    try {
      await _markAllAsRead();
    } catch (e) {
      emit(NotificationError(e.toString()));
      await loadNotifications();
    }
  }

  Future<void> respondToItineraryShare({
    required String notificationId,
    required String itineraryId,
    required bool accept,
  }) async {
    await _respondToItineraryShare(
      notificationId: notificationId,
      itineraryId: itineraryId,
      accept: accept,
    );
    await loadNotificationDetail(notificationId);
  }

  List<NotificationEntity> _applyLocalReadState(
    List<NotificationEntity> notifications,
  ) {
    if (_locallyReadIds.isEmpty) return notifications;

    return notifications.map((notification) {
      if (!_locallyReadIds.contains(notification.id)) return notification;
      return notification.copyWith(isUnread: false);
    }).toList();
  }
}
