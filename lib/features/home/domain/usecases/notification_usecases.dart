import 'package:travel_advisor_mobile/features/home/domain/entities/notification_entity.dart';
import 'package:travel_advisor_mobile/features/home/domain/repositories/notification_repository.dart';

class GetNotificationsUseCase {
  final NotificationRepository _repository;

  GetNotificationsUseCase(this._repository);

  Future<List<NotificationEntity>> call() => _repository.getNotifications();
}

class GetNotificationDetailUseCase {
  final NotificationRepository _repository;

  GetNotificationDetailUseCase(this._repository);

  Future<NotificationEntity> call(String id) =>
      _repository.getNotificationDetail(id);
}

class MarkAllNotificationsAsReadUseCase {
  final NotificationRepository _repository;

  MarkAllNotificationsAsReadUseCase(this._repository);

  Future<void> call() => _repository.markAllAsRead();
}

class MarkNotificationAsReadUseCase {
  final NotificationRepository _repository;

  MarkNotificationAsReadUseCase(this._repository);

  Future<NotificationEntity> call(String id) => _repository.markAsRead(id);
}
