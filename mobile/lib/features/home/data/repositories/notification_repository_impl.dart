import 'package:travel_advisor_mobile/features/home/data/datasources/notification_datasource.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/notification_entity.dart';
import 'package:travel_advisor_mobile/features/home/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationDataSource _dataSource;

  NotificationRepositoryImpl(this._dataSource);

  @override
  Future<List<NotificationEntity>> getNotifications() async {
    final models = await _dataSource.getNotifications();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<NotificationEntity> getNotificationDetail(String id) async {
    final model = await _dataSource.getNotificationDetail(id);
    return model.toEntity();
  }

  @override
  Future<NotificationEntity> markAsRead(String id) async {
    final model = await _dataSource.markAsRead(id);
    return model.toEntity();
  }

  @override
  Future<void> markAllAsRead() => _dataSource.markAllAsRead();

  @override
  Future<void> respondToItineraryShare({
    required String notificationId,
    required String itineraryId,
    required bool accept,
  }) {
    return _dataSource.respondToItineraryShare(
      notificationId: notificationId,
      itineraryId: itineraryId,
      accept: accept,
    );
  }
}
