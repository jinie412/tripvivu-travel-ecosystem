import 'dart:async';

import 'package:travel_advisor_mobile/core/network/dio_client.dart';
import 'package:travel_advisor_mobile/core/utils/auth_utils.dart';

enum FavoriteTargetType { place, itinerary }

class FavoriteChangedEvent {
  final FavoriteTargetType type;
  final String id;
  final bool isFavorite;

  const FavoriteChangedEvent({
    required this.type,
    required this.id,
    required this.isFavorite,
  });
}

class FavoriteRemoteDataSource {
  final DioClient _client;
  final StreamController<FavoriteChangedEvent> _changesController =
      StreamController<FavoriteChangedEvent>.broadcast();

  FavoriteRemoteDataSource(this._client);

  Stream<FavoriteChangedEvent> get changes => _changesController.stream;

  Future<bool> setPlaceFavorite(String placeId, bool isFavorite) async {
    final touristId = await AuthUtils.requireCurrentUserId();
    final path = '/collections/places/$placeId';
    final queryParameters = {'tourist_id': touristId};

    if (isFavorite) {
      await _client.dio.post(path, queryParameters: queryParameters);
    } else {
      await _client.dio.delete(path, queryParameters: queryParameters);
    }

    _changesController.add(
      FavoriteChangedEvent(
        type: FavoriteTargetType.place,
        id: placeId,
        isFavorite: isFavorite,
      ),
    );

    return isFavorite;
  }

  Future<bool> setItineraryFavorite(String itineraryId, bool isFavorite) async {
    final touristId = await AuthUtils.requireCurrentUserId();
    final path = '/collections/itineraries/$itineraryId';
    final queryParameters = {'tourist_id': touristId};

    if (isFavorite) {
      await _client.dio.post(path, queryParameters: queryParameters);
    } else {
      await _client.dio.delete(path, queryParameters: queryParameters);
    }

    _changesController.add(
      FavoriteChangedEvent(
        type: FavoriteTargetType.itinerary,
        id: itineraryId,
        isFavorite: isFavorite,
      ),
    );

    return isFavorite;
  }
}
