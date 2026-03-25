import 'package:equatable/equatable.dart';
import '../../domain/entities/destination.dart';
import '../../domain/entities/hotel.dart';
import '../../domain/entities/trip_suggestion.dart';
import '../../../itinerary/domain/entities/itinerary_entity.dart';
import '../../../city_detail/domain/entities/city_entities.dart';

abstract class ExploreState extends Equatable {
  const ExploreState();
  @override
  List<Object?> get props => [];
}

class ExploreInitial extends ExploreState {
  const ExploreInitial();
}

class ExploreLoading extends ExploreState {
  const ExploreLoading();
}

class ExploreLoaded extends ExploreState {
  final List<TripSuggestion> suggestions;
  final List<Destination> destinations;
  final List<Hotel> hotels;
  final List<CityRestaurant> restaurants;
  final ItineraryEntity? currentItinerary;

  const ExploreLoaded({
    required this.suggestions,
    required this.destinations,
    required this.hotels,
    required this.restaurants,
    this.currentItinerary,
  });

  @override
  List<Object?> get props => [suggestions, destinations, hotels, restaurants, currentItinerary];
}

class ExploreError extends ExploreState {
  final String message;
  const ExploreError(this.message);
  @override
  List<Object?> get props => [message];
}
