import 'itinerary_day_model.dart';

import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_detail_entity.dart';

class ItineraryDetailModel {
  final String id;
  final String title;
  final String destination;
  final String? tripIntent;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final bool isPublic;
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
  final List<ItineraryDayModel> days;
  final List<String> notes;
  final List<double> centerCoordinate;
  final List<VisitedRestaurantModel> visitedRestaurants;
  final bool trackingActive;

  const ItineraryDetailModel({
    required this.id,
    required this.title,
    required this.destination,
    this.tripIntent,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.isPublic = true,
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
  });

  factory ItineraryDetailModel.fromJson(Map<String, dynamic> json) {
    DateTime start = DateTime.now();
    DateTime end = DateTime.now();

    if (json['startDate'] != null) {
      start = DateTime.tryParse(json['startDate'].toString()) ?? DateTime.now();
    } else if (json['start_date'] != null) {
      start =
          DateTime.tryParse(json['start_date'].toString()) ?? DateTime.now();
    } else if (json['dateRangeLabel'] != null) {
      // e.g. "12 Th06 - 15 Th06, 2026", let's try to parse or fallback
      final parts = json['dateRangeLabel'].toString().split('-');
      if (parts.isNotEmpty) {
        // Just fallback to now
        start = DateTime.now();
      }
    }

    if (json['endDate'] != null) {
      end = DateTime.tryParse(json['endDate'].toString()) ?? DateTime.now();
    } else if (json['end_date'] != null) {
      end = DateTime.tryParse(json['end_date'].toString()) ?? DateTime.now();
    }

    return ItineraryDetailModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      destination: json['destination'] ?? '',
      tripIntent: (json['tripIntent'] ?? json['trip_intent'])?.toString(),
      startDate: start,
      endDate: end,
      status: json['status'] ?? '',
      isPublic: json['isPublic'] ?? json['is_public'] ?? true,
      durationDays:
          json['durationDays'] ??
          json['duration_days'] ??
          json['totalDays'] ??
          0,
      activitiesCount:
          json['activitiesCount'] ??
          json['activities_count'] ??
          json['totalPlaces'] ??
          0,
      totalLocations:
          json['totalLocations'] ??
          json['total_locations'] ??
          json['totalPlaces'] ??
          0,
      visitedLocations:
          json['visitedLocations'] ?? json['visited_locations'] ?? 0,
      hotelsCount: json['hotelsCount'] ?? json['hotels_count'] ?? 0,
      transportTurns: json['transportTurns'] ?? json['transport_turns'] ?? 0,
      estimatedBudget:
          (json['estimatedBudget'] ??
                  json['estimated_budget'] ??
                  json['totalBudget'] ??
                  0.0)
              .toDouble(),
      spentBudget: (json['spentBudget'] ?? json['spent_budget'] ?? 0.0)
          .toDouble(),
      placeCost: (json['placeCost'] ?? json['place_cost'] ?? 0.0).toDouble(),
      hotelCost: (json['hotelCost'] ?? json['hotel_cost'] ?? 0.0).toDouble(),
      transportCost: (json['transportCost'] ?? json['transport_cost'] ?? 0.0)
          .toDouble(),
      rideHailingTransportCost:
          (json['rideHailingTransportCost'] ??
                  json['ride_hailing_transport_cost'] ??
                  0.0)
              .toDouble(),
      currency: json['currency'] ?? 'VNĐ',
      days:
          (json['days'] as List?)
              ?.map(
                (e) => ItineraryDayModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      notes:
          (json['notes'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      centerCoordinate:
          ((json['centerCoordinate'] ?? json['center_coordinate']) as List?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          const [],
      visitedRestaurants:
          ((json['visitedRestaurants'] ?? json['visited_restaurants']) as List?)
              ?.map(
                (e) =>
                    VisitedRestaurantModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      trackingActive: json['tracking_active'] == true,
    );
  }

  ItineraryDetailEntity toEntity() {
    return ItineraryDetailEntity(
      id: id,
      title: title,
      destination: destination,
      tripIntent: tripIntent,
      startDate: startDate,
      endDate: endDate,
      status: status,
      isPublic: isPublic,
      durationDays: durationDays,
      activitiesCount: activitiesCount,
      totalLocations: totalLocations,
      visitedLocations: visitedLocations,
      hotelsCount: hotelsCount,
      transportTurns: transportTurns,
      estimatedBudget: estimatedBudget,
      spentBudget: spentBudget,
      placeCost: placeCost,
      hotelCost: hotelCost,
      transportCost: transportCost,
      rideHailingTransportCost: rideHailingTransportCost,
      currency: currency,
      days: days.map((e) => e.toEntity()).toList(),
      notes: notes,
      visitedRestaurants: visitedRestaurants.map((e) => e.toEntity()).toList(),
      centerCoordinate: centerCoordinate,
      trackingActive: trackingActive,
    );
  }
}

class VisitedRestaurantModel {
  final String name;
  final List<VisitedDishModel> dishes;
  final String imageUrl;

  const VisitedRestaurantModel({
    required this.name,
    required this.dishes,
    required this.imageUrl,
  });

  factory VisitedRestaurantModel.fromJson(Map<String, dynamic> json) {
    return VisitedRestaurantModel(
      name: json['name'] ?? '',
      dishes:
          (json['dishes'] as List?)
              ?.map((e) => VisitedDishModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      imageUrl: json['imageUrl'] ?? json['image_url'] ?? '',
    );
  }

  VisitedRestaurant toEntity() => VisitedRestaurant(
    name: name,
    dishes: dishes.map((e) => e.toEntity()).toList(),
    imageUrl: imageUrl,
  );
}

class VisitedDishModel {
  final String name;
  final double price;
  final int quantity;

  const VisitedDishModel({
    required this.name,
    required this.price,
    this.quantity = 1,
  });

  factory VisitedDishModel.fromJson(Map<String, dynamic> json) {
    return VisitedDishModel(
      name: json['name'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      quantity: json['quantity'] ?? 1,
    );
  }

  VisitedDish toEntity() =>
      VisitedDish(name: name, price: price, quantity: quantity);
}
