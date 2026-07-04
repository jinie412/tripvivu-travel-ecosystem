import 'package:travel_advisor_mobile/features/home/domain/entities/notification_entity.dart';

abstract class NotificationRepository {
  Future<List<NotificationEntity>> getNotifications();
  Future<NotificationEntity> getNotificationDetail(String id);
  Future<NotificationEntity> markAsRead(String id);
  Future<void> markAllAsRead();
  Future<void> respondToItineraryShare({
    required String notificationId,
    required String itineraryId,
    required bool accept,
  });
}
