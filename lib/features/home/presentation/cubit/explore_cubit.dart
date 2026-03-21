import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/home_usecases.dart';
import '../../../itinerary/domain/usecases/itinerary_usecases.dart';
import '../../../itinerary/domain/entities/itinerary_entity.dart';
import 'explore_state.dart';

class ExploreCubit extends Cubit<ExploreState> {
  final GetSuggestionsUseCase _getSuggestions;
  final GetDestinationsUseCase _getDestinations;
  final GetHotelsUseCase _getHotels;
  final GetItinerariesUseCase _getItineraries;

  ExploreCubit({
    required GetSuggestionsUseCase getSuggestions,
    required GetDestinationsUseCase getDestinations,
    required GetHotelsUseCase getHotels,
    required GetItinerariesUseCase getItineraries,
  })  : _getSuggestions = getSuggestions,
        _getDestinations = getDestinations,
        _getHotels = getHotels,
        _getItineraries = getItineraries,
        super(const ExploreInitial());

  Future<void> loadData() async {
    emit(const ExploreLoading());
    try {
      final results = await Future.wait([
        _getSuggestions(),
        _getDestinations(),
        _getHotels(),
        _getItineraries(),
      ]);
      final itins = results[3] as List<ItineraryEntity>;

      emit(ExploreLoaded(
        suggestions: results[0] as dynamic,
        destinations: results[1] as dynamic,
        hotels: results[2] as dynamic,
        currentItinerary: itins.isNotEmpty ? itins.first : null,
      ));
    } catch (e) {
      emit(ExploreError(e.toString()));
    }
  }
}
