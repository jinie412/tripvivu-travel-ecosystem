import 'package:flutter_bloc/flutter_bloc.dart';
import 'saved_state.dart';

import 'package:travel_advisor_mobile/features/city_detail/domain/entities/city_entities.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/destination.dart';
import 'package:travel_advisor_mobile/features/saved/domain/repositories/saved_repository.dart';

class SavedCubit extends Cubit<SavedState> {
  final SavedRepository repository;

  SavedCubit({required this.repository}) : super(SavedInitial());

  Future<void> loadSavedContent() async {
    emit(SavedLoading());
    try {
      final results = await Future.wait([
        repository.getFavoriteItineraries(),
        repository.getFavoritePlaces(),
      ]);

      emit(SavedLoaded(
        itineraries: (results[0] as List).cast<CityItinerary>(),
        places: (results[1] as List).cast<Destination>(),
      ));
    } catch (e) {
      emit(SavedError(e.toString()));
    }
  }
}