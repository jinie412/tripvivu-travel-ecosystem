import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_day_entity.dart';

class VisitedDish {
  final String name;
  final double price;
  final int quantity;

  const VisitedDish({
    required this.name,
    required this.price,
    this.quantity = 1,
  });
}

class VisitedRestaurant {
  final String name;
  final List<VisitedDish> dishes;
  final String imageUrl;

  const VisitedRestaurant({
    required this.name,
    required this.dishes,
    required this.imageUrl,
  });
}

class ItineraryDetailEntity {
  final String id;
  final String title;
  final String destination;
  final String? tripIntent;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final bool isPublic;
  final bool isFavorite;
  final int durationDays;
  final int activitiesCount;
  final int totalLocations;
  final int visitedLocations;
  final int hotelsCount;
  final int transportTurns;

  final double estimatedBudget;
  final double spentBudget;
  final double placeCost;
  final double hotelCost;
  final double transportCost;
  final double rideHailingTransportCost;
  final String currency;

  final List<ItineraryDayEntity> days;
  final List<String> notes;
  final List<VisitedRestaurant> visitedRestaurants;

  final List<double> centerCoordinate;
  final bool trackingActive;

  final String? dailyStartTime;
  final String? dailyEndTime;

  const ItineraryDetailEntity({
    required this.id,
    required this.title,
    required this.destination,
    this.tripIntent,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.isPublic = true,
    this.isFavorite = false,
    required this.durationDays,
    required this.activitiesCount,
    this.totalLocations = 0,
    this.visitedLocations = 0,
    required this.hotelsCount,
    required this.transportTurns,
    required this.estimatedBudget,
    required this.spentBudget,
    this.placeCost = 0,
    this.hotelCost = 0,
    this.transportCost = 0,
    this.rideHailingTransportCost = 0,
    this.currency = 'VNĐ',
    this.days = const [],
    this.notes = const [],
    this.visitedRestaurants = const [],
    this.centerCoordinate = const [],
    this.trackingActive = false,
    this.dailyStartTime,
    this.dailyEndTime,
  });

  ItineraryDetailEntity copyWith({
    String? id,
    String? title,
    String? destination,
    String? tripIntent,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    bool? isPublic,
    bool? isFavorite,
    int? durationDays,
    int? activitiesCount,
    int? totalLocations,
    int? visitedLocations,
    int? hotelsCount,
    int? transportTurns,
    double? estimatedBudget,
    double? spentBudget,
    double? placeCost,
    double? hotelCost,
    double? transportCost,
    double? rideHailingTransportCost,
    String? currency,
    List<ItineraryDayEntity>? days,
    List<String>? notes,
    List<VisitedRestaurant>? visitedRestaurants,
    List<double>? centerCoordinate,
    bool? trackingActive,
    String? dailyStartTime,
    String? dailyEndTime,
  }) {
    return ItineraryDetailEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      destination: destination ?? this.destination,
      tripIntent: tripIntent ?? this.tripIntent,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      isPublic: isPublic ?? this.isPublic,
      isFavorite: isFavorite ?? this.isFavorite,
      durationDays: durationDays ?? this.durationDays,
      activitiesCount: activitiesCount ?? this.activitiesCount,
      totalLocations: totalLocations ?? this.totalLocations,
      visitedLocations: visitedLocations ?? this.visitedLocations,
      hotelsCount: hotelsCount ?? this.hotelsCount,
      transportTurns: transportTurns ?? this.transportTurns,
      estimatedBudget: estimatedBudget ?? this.estimatedBudget,
      spentBudget: spentBudget ?? this.spentBudget,
      placeCost: placeCost ?? this.placeCost,
      hotelCost: hotelCost ?? this.hotelCost,
      transportCost: transportCost ?? this.transportCost,
      rideHailingTransportCost:
          rideHailingTransportCost ?? this.rideHailingTransportCost,
      currency: currency ?? this.currency,
      days: days ?? this.days,
      notes: notes ?? this.notes,
      visitedRestaurants: visitedRestaurants ?? this.visitedRestaurants,
      centerCoordinate: centerCoordinate ?? this.centerCoordinate,
      trackingActive: trackingActive ?? this.trackingActive,
      dailyStartTime: dailyStartTime ?? this.dailyStartTime,
      dailyEndTime: dailyEndTime ?? this.dailyEndTime,
    );
  }
}
