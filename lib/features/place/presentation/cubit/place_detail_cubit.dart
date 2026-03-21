import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_place_detail_usecase.dart';
import 'place_detail_state.dart';

class PlaceDetailCubit extends Cubit<PlaceDetailState> {
  final GetPlaceDetailUseCase getPlaceDetailUseCase;

  PlaceDetailCubit({required this.getPlaceDetailUseCase}) : super(const PlaceDetailInitial());

  Future<void> loadPlaceDetail(String id) async {
    emit(const PlaceDetailLoading());
    try {
      final detail = await getPlaceDetailUseCase(id);
      emit(PlaceDetailLoaded(detail));
    } catch (e) {
      emit(PlaceDetailError(e.toString()));
    }
  }

  void toggleFavorite() {
    if (state is PlaceDetailLoaded) {
      final currentState = state as PlaceDetailLoaded;
      final updatedPlace = currentState.placeDetail.copyWith(
        isFavorite: !currentState.placeDetail.isFavorite,
      );
      emit(PlaceDetailLoaded(updatedPlace));
    }
  }
}
