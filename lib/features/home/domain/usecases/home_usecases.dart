import 'package:travel_advisor_mobile/features/city_detail/domain/entities/city_entities.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/destination.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/hotel.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/trip_suggestion.dart';
import 'package:travel_advisor_mobile/features/home/domain/repositories/home_repository.dart';

class GetSuggestionsUseCase {
  final HomeRepository _repo;
  GetSuggestionsUseCase(this._repo);
  Future<List<TripSuggestion>> call() => _repo.getSuggestions();
}

class GetDestinationsUseCase {
  final HomeRepository _repo;
  GetDestinationsUseCase(this._repo);
  Future<List<Destination>> call() => _repo.getDestinations();
}

class GetHotelsUseCase {
  final HomeRepository _repo;
  GetHotelsUseCase(this._repo);
  Future<List<Hotel>> call() => _repo.getHotels();
}

class GetRestaurantsUseCase {
  final HomeRepository _repo;
  GetRestaurantsUseCase(this._repo);
  Future<List<CityRestaurant>> call() => _repo.getRestaurants();
}