import 'package:flutter/foundation.dart';
import 'package:travel_advisor_mobile/core/network/dio_client.dart';
import 'package:travel_advisor_mobile/core/utils/auth_utils.dart';

class ActivityService {
  final DioClient _dioClient;

  ActivityService(this._dioClient);

  Future<void> _track({
    required String actionType,
    String? placeId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final touristId = await AuthUtils.getCurrentUserId();
      if (touristId == null || touristId.isEmpty) {
        debugPrint('[ActivityLog] ✗ $actionType — bỏ qua: chưa đăng nhập');
        return;
      }

      debugPrint(
        '[ActivityLog] → $actionType'
        '${placeId != null ? ' | place=$placeId' : ''}'
        ' | tourist=$touristId',
      );

      final response = await _dioClient.dio.post(
        '/activity/track',
        data: {
          'tourist_id': touristId,
          'action_type': actionType,
          if (placeId != null) 'place_id': placeId,
        },
      );

      debugPrint('[ActivityLog] ✓ $actionType ghi thành công (${response.statusCode})');
    } catch (e) {
      debugPrint('[ActivityLog] ✗ $actionType thất bại: $e');
    }
  }

  /// User tap vào card POI
  Future<void> trackClick(String placeId) =>
      _track(actionType: 'click', placeId: placeId);

  /// User ở lại trang (50% pixel) >= 2s
  Future<void> trackView(String placeId) =>
      _track(actionType: 'view', placeId: placeId);

  /// User lưu POI vào danh sách yêu thích
  Future<void> trackSave(String placeId) =>
      _track(actionType: 'save', placeId: placeId);

  /// User bỏ lưu POI
  Future<void> trackUnsave(String placeId) =>
      _track(actionType: 'unsave', placeId: placeId);

  /// User nhập từ khóa tìm kiếm và có kết quả trả về
  Future<void> trackSearch() =>
      _track(actionType: 'search');

  /// User nhấn vào một địa điểm cụ thể từ kết quả tìm kiếm
  Future<void> trackSearchPlace(String placeId) =>
      _track(actionType: 'search', placeId: placeId);

  /// User check-in tại địa điểm thực tế
  Future<void> trackVisited(String placeId) =>
      _track(actionType: 'visited', placeId: placeId);

  /// User viết đánh giá
  Future<void> trackReview(String placeId) =>
      _track(actionType: 'review', placeId: placeId);

  /// User chấm điểm
  Future<void> trackRating(String placeId) =>
      _track(actionType: 'rating', placeId: placeId);
}
