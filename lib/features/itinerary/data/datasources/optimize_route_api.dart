import 'package:travel_advisor_mobile/core/network/dio_client.dart';
import 'package:travel_advisor_mobile/core/di/injection_container.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_activity_entity.dart';

class OptimizeRouteApi {
  static Future<List<ItineraryActivityEntity>> optimizeDay(
    List<ItineraryActivityEntity> activities, {
    String? dailyStartTime,
    String? dailyEndTime,
  }) async {
    if (activities.length <= 1) return activities;
    
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
            // ─── Fields mới cho TSPTW ───────────────────
            'durationMinutes':   duration,
            'isLocked':          false,          // entity chưa có field này → mặc định false
            'lockedArriveTime':  null,
            'openHourCompressed': a.openHourCompressed,
          };
        }).toList(),
        if (dailyStartTime != null) 'dailyStartTime': dailyStartTime,
        if (dailyEndTime != null) 'dailyEndTime': dailyEndTime,
      };

      final response = await client.dio.post('/itinerary/optimize-day', data: payload);
      
      final data = response.data['optimized'] as List;
      if (data.isEmpty) return [];

      // Build lookup map để tra nhanh bằng id
      final originalMap = {for (final a in activities) a.id: a};

      return data.map((json) {
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
    } catch (e) {
      print('Error optimizing route: $e');
      return activities;
    }
  }
}
