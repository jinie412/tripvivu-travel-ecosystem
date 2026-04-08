import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:travel_advisor_mobile/features/saved/domain/usecases/get_favorite_itineraries_usecase.dart';
import 'package:travel_advisor_mobile/features/saved/domain/usecases/get_favorite_places_usecase.dart';
import 'saved_state.dart';

class SavedCubit extends Cubit<SavedState> {
  final GetFavoriteItinerariesUseCase getFavoriteItinerariesUseCase;
  final GetFavoritePlacesUseCase getFavoritePlacesUseCase;

  SavedCubit({
    required this.getFavoriteItinerariesUseCase,
    required this.getFavoritePlacesUseCase,
  }) : super(SavedInitial());

  Future<void> loadSavedContent({int page = 1, int limit = 5}) async {
    emit(SavedLoading());
    try {
      final results = await Future.wait([
        getFavoriteItinerariesUseCase(page: page, limit: limit),
        getFavoritePlacesUseCase(page: page, limit: limit),
      ]);

      emit(SavedLoaded(
        itineraries: (results[0] as List).cast(),
        places: (results[1] as List).cast(),
      ));
    } catch (e) {
      emit(SavedError(e.toString()));
    }
  }
}