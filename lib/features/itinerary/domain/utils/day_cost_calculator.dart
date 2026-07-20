import '../entities/itinerary_day_entity.dart';
import '../entities/itinerary_activity_entity.dart';

class DayCostBreakdown {
  final double placeCost;
  final double transportShare;
  final double total;

  DayCostBreakdown({
    required this.placeCost,
    required this.transportShare,
    required this.total,
  });
}

class DayTravelStats {
  final double distanceKm;
  final int travelMinutes;
  final int sightseeingMinutes;

  DayTravelStats({
    required this.distanceKm,
    required this.travelMinutes,
    required this.sightseeingMinutes,
  });
}

class DayCostCalculator {
  static bool isHotelStart(ItineraryActivityEntity activity) {
    final category = (activity.category ?? '').trim().toLowerCase();
    if (category.isNotEmpty) {
      return category == 'hotel' ||
          category.contains('lưu trú') ||
          category.contains('khách sạn') ||
          category.contains('accommodation');
    }
    final title = activity.title.toLowerCase();
    return title.contains('hotel') ||
        title.contains('khách sạn') ||
        title.contains('resort') ||
        title.contains('homestay') ||
        title.contains('villa');
  }

  static List<ItineraryActivityEntity> visitActivities(ItineraryDayEntity day) {
    return day.activities
        .where((activity) => !isHotelStart(activity))
        .toList();
  }

  static DayCostBreakdown computeDaily({
    required ItineraryDayEntity day,
    required int adultCount,
    required int childCount,
    required double childPriceRatio,
  }) {
    final visits = visitActivities(day);
    final placeCostPerAdult = visits.fold(0.0, (sum, item) => sum + item.price);
    
    final groupPlaceCost = placeCostPerAdult * adultCount + (placeCostPerAdult * childPriceRatio) * childCount;
    final groupTransportCost = day.activities.fold(0.0, (sum, item) => sum + item.transportCost);

    // KHÔNG cộng tiền khách sạn vào tổng ngày. KHÔNG cộng xăng xe nữa (giờ
    // hiển thị riêng 1 mục "cả chuyến" giống khách sạn, xem
    // itinerary_summary_screen.dart _buildTransportOverviewRow) — transportShare
    // vẫn trả về để chỗ khác dùng nếu cần, chỉ không cộng vào total.
    final total = groupPlaceCost;

    return DayCostBreakdown(
      placeCost: groupPlaceCost,
      transportShare: groupTransportCost,
      total: total,
    );
  }

  /// "HH:mm" -> phút kể từ 0h. Trả về null nếu parse lỗi (giữ nguyên hành vi
  /// không tính thay vì crash/hiện số sai).
  static int? _parseMinutes(String time) {
    final parts = time.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }

  /// Tổng km di chuyển, tổng giờ di chuyển (transitToNext giữa các hoạt
  /// động) và tổng giờ tham quan (endTime-startTime của các địa điểm ĐÃ ghé
  /// thăm/dự kiến, không tính dòng khách sạn) trong 1 ngày — dùng cho card
  /// tổng quan ngày ở màn tổng quan lịch trình.
  static DayTravelStats travelStats(ItineraryDayEntity day) {
    double distanceKm = 0;
    int travelMinutes = 0;
    for (final activity in day.activities) {
      distanceKm += activity.transitDistanceKm ?? 0;
      travelMinutes += activity.transitDurationMinutes ?? 0;
    }

    int sightseeingMinutes = 0;
    for (final activity in visitActivities(day)) {
      final start = _parseMinutes(activity.startTime);
      final end = _parseMinutes(activity.endTime);
      if (start == null || end == null) continue;
      final diff = end - start;
      if (diff > 0) sightseeingMinutes += diff;
    }

    return DayTravelStats(
      distanceKm: distanceKm,
      travelMinutes: travelMinutes,
      sightseeingMinutes: sightseeingMinutes,
    );
  }
}
