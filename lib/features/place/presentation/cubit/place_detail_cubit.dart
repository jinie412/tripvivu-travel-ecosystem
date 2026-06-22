import 'package:flutter_bloc/flutter_bloc.dart';
import 'place_detail_state.dart';

import 'package:travel_advisor_mobile/features/place/domain/usecases/get_place_detail_usecase.dart';
import 'package:travel_advisor_mobile/features/saved/data/datasources/favorite_remote_datasource.dart';

class PlaceDetailCubit extends Cubit<PlaceDetailState> {
  final GetPlaceDetailUseCase getPlaceDetailUseCase;
  final FavoriteRemoteDataSource favoriteRemoteDataSource;

  PlaceDetailCubit({
    required this.getPlaceDetailUseCase,
    required this.favoriteRemoteDataSource,
  }) : super(const PlaceDetailInitial());

  Future<void> loadPlaceDetail(String id) async {
    emit(const PlaceDetailLoading());
    try {
      final detail = await getPlaceDetailUseCase(id);
      emit(PlaceDetailLoaded(detail));
    } catch (e) {
      emit(PlaceDetailError(e.toString()));
    }
  }

  Future<bool?> toggleFavorite() async {
    if (state is PlaceDetailLoaded) {
      final currentState = state as PlaceDetailLoaded;
      final nextFavorite = !currentState.placeDetail.isFavorite;
      final updatedPlace = currentState.placeDetail.copyWith(
        isFavorite: nextFavorite,
      );
      emit(PlaceDetailLoaded(updatedPlace));

      try {
        await favoriteRemoteDataSource.setPlaceFavorite(
          currentState.placeDetail.id,
          nextFavorite,
        );
        return nextFavorite;
      } catch (_) {
        emit(PlaceDetailLoaded(currentState.placeDetail));
        return null;
      }
    }

    return null;
  }

  void syncFavoriteState(String placeId, bool isFavorite) {
    final currentState = state;
    if (currentState is! PlaceDetailLoaded) {
      return;
    }

    if (currentState.placeDetail.id != placeId ||
        currentState.placeDetail.isFavorite == isFavorite) {
      return;
    }

    emit(
      PlaceDetailLoaded(
        currentState.placeDetail.copyWith(isFavorite: isFavorite),
      ),
    );
  }
}
