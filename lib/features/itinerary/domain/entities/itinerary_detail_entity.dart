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
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final bool isPublic;
  
  final int durationDays;
  final int activitiesCount;
  final int hotelsCount;
  final int transportTurns;
  
  final double estimatedBudget;
  final double spentBudget;
  final String currency;
  
  final List<ItineraryDayEntity> days;
  final List<String> notes;
  final List<VisitedRestaurant> visitedRestaurants;
  
  final List<double> centerCoordinate;

  const ItineraryDetailEntity({
    required this.id,
    required this.title,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.isPublic = true,
    required this.durationDays,
    required this.activitiesCount,
    required this.hotelsCount,
    required this.transportTurns,
    required this.estimatedBudget,
    required this.spentBudget,
    this.currency = 'VNĐ',
    this.days = const [],
    this.notes = const [],
    this.visitedRestaurants = const [],
    this.centerCoordinate = const [],
  });
}
