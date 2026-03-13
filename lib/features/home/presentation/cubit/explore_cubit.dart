import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/home_usecases.dart';
import 'explore_state.dart';

class ExploreCubit extends Cubit<ExploreState> {
  final GetSuggestionsUseCase _getSuggestions;
  final GetDestinationsUseCase _getDestinations;
  final GetHotelsUseCase _getHotels;

  ExploreCubit({
    required GetSuggestionsUseCase getSuggestions,
    required GetDestinationsUseCase getDestinations,
    required GetHotelsUseCase getHotels,
  })  : _getSuggestions = getSuggestions,
        _getDestinations = getDestinations,
        _getHotels = getHotels,
        super(const ExploreInitial());

  Future<void> loadData() async {
    emit(const ExploreLoading());
    try {
      final results = await Future.wait([
        _getSuggestions(),
        _getDestinations(),
        _getHotels(),
      ]);
      emit(ExploreLoaded(
        suggestions: results[0] as dynamic,
        destinations: results[1] as dynamic,
        hotels: results[2] as dynamic,
      ));
    } catch (e) {
      emit(ExploreError(e.toString()));
    }
  }
}
