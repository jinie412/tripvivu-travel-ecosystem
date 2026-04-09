import 'package:travel_advisor_mobile/core/utils/auth_utils.dart';
import 'package:travel_advisor_mobile/features/home/data/models/notification_model.dart';
import 'package:travel_advisor_mobile/core/network/dio_client.dart';

abstract class NotificationDataSource {
  Future<List<NotificationModel>> getNotifications();
}

class MockNotificationDataSource implements NotificationDataSource {
  @override
  Future<List<NotificationModel>> getNotifications() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return [
      const NotificationModel(
        id: 'notif-001',
        title: 'Lịch trình sắp diễn ra',
        content: 'Chuyến du lịch khám phá Đà Lạt của bạn sẽ bắt đầu vào ngày mai. Đừng quên kiểm tra hành lý nhé!',
        notificationType: 'itinerary',
        status: 'unread',
        isGlobal: false,
        sentAt: '2026-04-08T10:30:00Z',
        timeLabel: '5 phút trước',
        iconKey: 'map',
        isUnread: true,
      ),
      const NotificationModel(
        id: 'notif-002',
        title: 'Đánh giá địa điểm',
        content: 'Bạn cảm thấy Thác Pongour như thế nào? Hãy để lại đánh giá để nhận thêm điểm thưởng.',
        notificationType: 'review',
        status: 'unread',
        isGlobal: false,
        sentAt: '2026-04-08T07:30:00Z',
        timeLabel: '2 giờ trước',
        iconKey: 'star',
        isUnread: true,
      ),
      const NotificationModel(
        id: 'notif-003',
        title: 'Đơn hàng ẩm thực đã sẵn sàng',
        content: 'Món Bánh mì xíu mại (#TRV123) của bạn đã chuẩn bị xong. Vui lòng đến nhận món.',
        notificationType: 'food',
        status: 'read',
        isGlobal: false,
        sentAt: '2026-04-07T15:00:00Z',
        timeLabel: 'Hôm qua',
        iconKey: 'restaurant',
        isUnread: false,
      ),
    ];
  }
}

class RemoteNotificationDataSource implements NotificationDataSource {
  final DioClient _client;

  RemoteNotificationDataSource(this._client);

  @override
  Future<List<NotificationModel>> getNotifications() async {
    final touristId = await AuthUtils.requireCurrentUserId();
    final response = await _client.dio.get(
      '/notifications',
      queryParameters: {'tourist_id': touristId},
    );

    final data = response.data as Map<String, dynamic>;
    final notificationsJson = _asList(data['notifications']);

    return notificationsJson.map((item) => NotificationModel.fromJson(item)).toList();
  }



  List<Map<String, dynamic>> _asList(dynamic raw) {
    if (raw is! List) {
      return const [];
    }
    return raw.whereType<Map<String, dynamic>>().toList();
  }
}
