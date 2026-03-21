import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/home_usecases.dart';
import '../../../itinerary/domain/usecases/itinerary_usecases.dart';
import '../../../itinerary/domain/entities/itinerary_entity.dart';
import '../../domain/entities/destination.dart';
import '../../domain/entities/hotel.dart';
import '../../domain/entities/trip_suggestion.dart';
import '../../../city_detail/domain/entities/city_entities.dart';
import 'explore_state.dart';

class ExploreCubit extends Cubit<ExploreState> {
  final GetSuggestionsUseCase _getSuggestions;
  final GetDestinationsUseCase _getDestinations;
  final GetHotelsUseCase _getHotels;
  final GetRestaurantsUseCase _getRestaurants;
  final GetItinerariesUseCase _getItineraries;

  ExploreCubit({
    required GetSuggestionsUseCase getSuggestions,
    required GetDestinationsUseCase getDestinations,
    required GetHotelsUseCase getHotels,
    required GetRestaurantsUseCase getRestaurants,
    required GetItinerariesUseCase getItineraries,
  })  : _getSuggestions = getSuggestions,
        _getDestinations = getDestinations,
        _getHotels = getHotels,
        _getRestaurants = getRestaurants,
        _getItineraries = getItineraries,
        super(const ExploreInitial());

  Future<void> loadData() async {
    emit(const ExploreLoading());
    try {
      final List<TripSuggestion> s = await _getSuggestions();
      final List<Destination> d = await _getDestinations();
      final List<Hotel> h = await _getHotels();
      final List<CityRestaurant> r = await _getRestaurants();
      final List<ItineraryEntity> itins = await _getItineraries();

      emit(ExploreLoaded(
        suggestions: s,
        destinations: d,
        hotels: h,
        restaurants: r,
        currentItinerary: itins.isNotEmpty ? itins.first : null,
      ));
    } catch (e) {
      emit(ExploreError(e.toString()));
    }
  }
}
