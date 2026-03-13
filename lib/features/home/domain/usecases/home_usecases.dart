import '../entities/destination.dart';
import '../entities/hotel.dart';
import '../entities/trip_suggestion.dart';
import '../repositories/home_repository.dart';

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
