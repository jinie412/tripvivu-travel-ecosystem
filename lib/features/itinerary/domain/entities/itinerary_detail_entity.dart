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

class ItineraryMemberEntity {
  final String id;
  final String fullName;
  final String avatarUrl;
  final bool isOwner;

  const ItineraryMemberEntity({
    required this.id,
    required this.fullName,
    this.avatarUrl = '',
    this.isOwner = false,
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
  final String? creatorId;
  final bool isOwner;
  final List<ItineraryMemberEntity> members;
  final int durationDays;
  final int activitiesCount;
  final int totalLocations;
  final int visitedLocations;
  final int hotelsCount;
  final int transportTurns;

  // Per-adult estimated cost for the whole itinerary (summed across all
  // days) — never a group total, never divided by participantCount.
  final double estimatedBudget;
  // User's original input budget ceiling (trip_budget_total), also per
  // adult. 0 when unknown (e.g. itineraries created before this field
  // existed). Kept separate from estimatedBudget so the UI can show both and
  // warn when the calculated cost exceeds 90% of it.
  final double userBudget;
  final int participantCount;
  final int adultCount;
  final int childCount;
  // Ratio applied to estimatedBudget/userBudget to get the child rate
  // (e.g. 0.7 = child pays 70% of an adult's rate).
  final double childPriceRatio;
  // Display-only, computed fresh from estimatedBudget/adultCount/childCount
  // by the backend — never stored, never divided back into a per-adult
  // figure.
  final double estimatedCostForGroup;
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
  // 'DRIVING' | 'MOTORBIKE' — dùng để vẽ đúng đường đi (Goong/Google Maps
  // vehicle param), thay vì luôn mặc định ô tô như trước.
  final String travelMode;

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
    this.creatorId,
    this.isOwner = true,
    this.members = const [],
    required this.durationDays,
    required this.activitiesCount,
    this.totalLocations = 0,
    this.visitedLocations = 0,
    required this.hotelsCount,
    required this.transportTurns,
    required this.estimatedBudget,
    this.userBudget = 0,
    this.participantCount = 1,
    this.adultCount = 1,
    this.childCount = 0,
    this.childPriceRatio = 0.7,
    this.estimatedCostForGroup = 0,
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
    this.travelMode = 'DRIVING',
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
    String? creatorId,
    bool? isOwner,
    List<ItineraryMemberEntity>? members,
    int? durationDays,
    int? activitiesCount,
    int? totalLocations,
    int? visitedLocations,
    int? hotelsCount,
    int? transportTurns,
    double? estimatedBudget,
    double? userBudget,
    int? participantCount,
    int? adultCount,
    int? childCount,
    double? childPriceRatio,
    double? estimatedCostForGroup,
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
    String? travelMode,
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
      creatorId: creatorId ?? this.creatorId,
      isOwner: isOwner ?? this.isOwner,
      members: members ?? this.members,
      durationDays: durationDays ?? this.durationDays,
      activitiesCount: activitiesCount ?? this.activitiesCount,
      totalLocations: totalLocations ?? this.totalLocations,
      visitedLocations: visitedLocations ?? this.visitedLocations,
      hotelsCount: hotelsCount ?? this.hotelsCount,
      transportTurns: transportTurns ?? this.transportTurns,
      estimatedBudget: estimatedBudget ?? this.estimatedBudget,
      userBudget: userBudget ?? this.userBudget,
      participantCount: participantCount ?? this.participantCount,
      adultCount: adultCount ?? this.adultCount,
      childCount: childCount ?? this.childCount,
      childPriceRatio: childPriceRatio ?? this.childPriceRatio,
      estimatedCostForGroup: estimatedCostForGroup ?? this.estimatedCostForGroup,
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
      travelMode: travelMode ?? this.travelMode,
    );
  }
}
