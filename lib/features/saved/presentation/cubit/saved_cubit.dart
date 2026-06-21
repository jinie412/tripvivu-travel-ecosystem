import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:travel_advisor_mobile/features/saved/data/datasources/favorite_remote_datasource.dart';
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

  void applyFavoriteChange(FavoriteChangedEvent event) {
    final currentState = state;
    if (currentState is! SavedLoaded || event.isFavorite) {
      return;
    }

    if (event.type == FavoriteTargetType.place) {
      emit(
        SavedLoaded(
          itineraries: currentState.itineraries,
          places: currentState.places
              .where((item) => item.id != event.id)
              .toList(growable: false),
        ),
      );
      return;
    }

    emit(
      SavedLoaded(
        itineraries: currentState.itineraries
            .where((item) => item.id != event.id)
            .toList(growable: false),
        places: currentState.places,
      ),
    );
  }

  Future<void> loadSavedContent({
    int page = 1,
    int limit = 50,
    bool silent = false,
  }) async {
    final previousState = state;
    if (!silent) {
      emit(SavedLoading());
    }
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
      if (silent && previousState is SavedLoaded) {
        emit(previousState);
      } else {
        emit(SavedError(e.toString()));
      }
    }
  }
}
