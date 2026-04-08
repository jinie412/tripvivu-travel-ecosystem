import 'package:travel_advisor_mobile/features/home/domain/entities/notification_entity.dart';

abstract class NotificationRepository {
  Future<List<NotificationEntity>> getNotifications();
}
