import 'package:travel_advisor_mobile/core/network/dio_client.dart';
import 'package:travel_advisor_mobile/core/di/injection_container.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_activity_entity.dart';
import 'package:dio/dio.dart';

class OptimizeRouteApi {
  static Future<({List<ItineraryActivityEntity> optimized, List<String> reorderNotes})> optimizeDay(
    List<ItineraryActivityEntity> activities, {
    String? dailyStartTime,
    String? dailyEndTime,
    bool allowReduceTime = false,
    /// ID của activity vừa được thêm mới — optimizer sẽ chèn nó vào vị trí tối ưu
    /// thay vì buộc nó phải đứng sau tất cả activities cũ.
    String? newActivityId,
    String? editedActivityId,
    /// Ngày tham quan "YYYY-MM-DD" — dùng để parse openHourCompressed đúng ngày
    /// (chợ đêm mở tối, bãi biển mở sáng, v.v.)
    String? visitDate,
  }) async {
    if (activities.length <= 1) return (optimized: activities, reorderNotes: <String>[]);

    try {
      final client = sl<DioClient>();

      final payload = {
        'activities': activities.map((a) {
          // Tính duration từ startTime/endTime
          int startMin = 0, endMin = 60;
          try {
            final sp = a.startTime.split(':');
            final ep = a.endTime.split(':');
            startMin = int.parse(sp[0]) * 60 + int.parse(sp[1]);
            endMin   = int.parse(ep[0]) * 60 + int.parse(ep[1]);
          } catch (_) {}
          final duration = (endMin - startMin) > 0 ? (endMin - startMin) : 60;

          return {
            'id':                a.id,
            'placeId':           a.placeId,
            'title':             a.title,
            'startTime':         a.startTime,
            'endTime':           a.endTime,
            'latitude':          a.latitude,
            'longitude':         a.longitude,
            'locationName':      a.locationName,
            'address':           a.address,
            'imageUrl':          a.imageUrl,
            'category':          a.category,
            'price':             a.price,
            'rating':            a.rating,
            'reviewCount':       a.reviewCount,
            // ─── Fields cho TSPTW ──────────────────────
            'durationMinutes':   duration,
            'isLocked':          editedActivityId != null && a.id == editedActivityId,
            'lockedArriveTime':  editedActivityId != null && a.id == editedActivityId ? a.startTime : null,
            'openHourCompressed': a.openHourCompressed,
            // is_new = true → optimizer có thể chèn activity này vào BẤT KỲ vị trí nào,
            // không bị ràng buộc phải đứng sau tất cả activity cũ.
            'isNew': newActivityId != null && a.id == newActivityId,
          };
        }).toList(),
        if (dailyStartTime != null) 'dailyStartTime': dailyStartTime,
        if (dailyEndTime != null) 'dailyEndTime': dailyEndTime,
        'allowReduceTime': allowReduceTime,
        if (visitDate != null) 'visitDate': visitDate,
      };

      final response = await client.dio.post('/itinerary/optimize-day', data: payload);
      
      final data = response.data['optimized'] as List;
      final reorderNotes = (response.data['reorderNotes'] as List?)?.map((e) => e.toString()).toList() ?? [];
      
      if (data.isEmpty) return (optimized: <ItineraryActivityEntity>[], reorderNotes: <String>[]);

      // Build lookup map để tra nhanh bằng id
      final originalMap = {for (final a in activities) a.id: a};

      final mappedOptimized = data.map((json) {
        final String id = json['id'] ?? '';
        final original = originalMap[id];

        if (original == null) {
          // Fallback nếu không tìm thấy — tạo entity tối thiểu
          return ItineraryActivityEntity(
            id: id,
            title: json['title'] ?? '',
            startTime: json['startTime'] ?? '08:00',
            endTime: json['endTime'] ?? '09:00',
            locationName: json['locationName'] ?? '',
            address: json['address'] ?? '',
            imageUrl: json['imageUrl'] ?? '',
            category: json['category'],
          );
        }

        // Giữ toàn bộ dữ liệu gốc, chỉ cập nhật time và transport
        return original.copyWith(
          startTime:     json['startTime'] ?? original.startTime,
          endTime:       json['endTime']   ?? original.endTime,
          transportInfo: json['transportInfo'] ?? original.transportInfo,
        );
      }).toList();
      
      return (optimized: mappedOptimized, reorderNotes: reorderNotes);
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 400 && e.response?.data?['message'] == 'SCHEDULE_FULL') {
        throw Exception('SCHEDULE_FULL');
      }
      print('Error optimizing route: $e');
      return (optimized: activities, reorderNotes: <String>[]);
    }
  }
}
