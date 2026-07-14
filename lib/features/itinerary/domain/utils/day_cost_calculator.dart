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
    
    // KHÔNG cộng tiền khách sạn vào tổng ngày
    final total = groupPlaceCost + groupTransportCost;

    return DayCostBreakdown(
      placeCost: groupPlaceCost,
      transportShare: groupTransportCost,
      total: total,
    );
  }
}
