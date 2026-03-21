import '../../domain/entities/itinerary_detail_entity.dart';
import 'itinerary_day_model.dart';

class ItineraryDetailModel {
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
  final List<ItineraryDayModel> days;
  final List<String> notes;
  final List<double> centerCoordinate;
  final List<VisitedRestaurantModel> visitedRestaurants;

  const ItineraryDetailModel({
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

  ItineraryDetailEntity toEntity() {
    return ItineraryDetailEntity(
      id: id,
      title: title,
      destination: destination,
      startDate: startDate,
      endDate: endDate,
      status: status,
      isPublic: isPublic,
      durationDays: durationDays,
      activitiesCount: activitiesCount,
      hotelsCount: hotelsCount,
      transportTurns: transportTurns,
      estimatedBudget: estimatedBudget,
      spentBudget: spentBudget,
      currency: currency,
      days: days.map((e) => e.toEntity()).toList(),
      notes: notes,
      visitedRestaurants: visitedRestaurants.map((e) => e.toEntity()).toList(),
      centerCoordinate: centerCoordinate,
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

  VisitedDish toEntity() => VisitedDish(
        name: name,
        price: price,
        quantity: quantity,
      );
}
