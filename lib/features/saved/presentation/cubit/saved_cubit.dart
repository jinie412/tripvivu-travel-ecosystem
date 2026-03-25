import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/saved_repository.dart';
import '../../../city_detail/domain/entities/city_entities.dart';
import '../../../home/domain/entities/destination.dart';
import 'saved_state.dart';

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
