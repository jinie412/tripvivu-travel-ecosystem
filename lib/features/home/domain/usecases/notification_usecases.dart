import 'package:travel_advisor_mobile/features/home/domain/entities/notification_entity.dart';
import 'package:travel_advisor_mobile/features/home/domain/repositories/notification_repository.dart';

class GetNotificationsUseCase {
  final NotificationRepository _repository;

  GetNotificationsUseCase(this._repository);

  Future<List<NotificationEntity>> call() => _repository.getNotifications();
}
