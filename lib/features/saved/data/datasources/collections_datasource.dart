import 'package:travel_advisor_mobile/core/network/dio_client.dart';
import 'package:travel_advisor_mobile/core/utils/auth_utils.dart';
import 'package:travel_advisor_mobile/features/saved/data/models/favorite_itinerary_model.dart';
import 'package:travel_advisor_mobile/features/saved/data/models/favorite_place_model.dart';

abstract class CollectionsDataSource {
  Future<List<FavoriteItineraryModel>> getFavoriteItineraries({int page = 1, int limit = 5});
  Future<List<FavoritePlaceModel>> getFavoritePlaces({int page = 1, int limit = 5});
}

/// Remote implementation - fetches from backend API
class RemoteCollectionsDataSource implements CollectionsDataSource {
  final DioClient _client;

  RemoteCollectionsDataSource(this._client);

  @override
  Future<List<FavoriteItineraryModel>> getFavoriteItineraries({
    int page = 1,
    int limit = 5,
  }) async {
    final touristId = await AuthUtils.requireCurrentUserId();

    final response = await _client.dio.get(
      '/collections/itineraries',
      queryParameters: {
        'tourist_id': touristId,
        'page': page,
        'limit': limit,
      },
    );

    final data = response.data as Map<String, dynamic>;
    final itemsList = _asList(data['data']);

    return itemsList
        .map((json) => FavoriteItineraryModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<FavoritePlaceModel>> getFavoritePlaces({
    int page = 1,
    int limit = 5,
  }) async {
    final touristId = await AuthUtils.requireCurrentUserId();

    final response = await _client.dio.get(
      '/collections/places',
      queryParameters: {
        'tourist_id': touristId,
        'page': page,
        'limit': limit,
      },
    );

    final data = response.data as Map<String, dynamic>;
    final itemsList = _asList(data['data']);

    return itemsList
        .map((json) => FavoritePlaceModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  List<dynamic> _asList(dynamic raw) {
    if (raw is! List) {
      return const [];
    }
    return raw;
  }
}

/// Mock implementation - for testing without backend
class MockCollectionsDataSource implements CollectionsDataSource {
  @override
  Future<List<FavoriteItineraryModel>> getFavoriteItineraries({
    int page = 1,
    int limit = 5,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return [
      const FavoriteItineraryModel(
        id: '1',
        title: 'Kỳ nghỉ Quy Nhơn',
        location: 'Quy Nhơn',
        days: 4,
        participantCount: 1,
        status: 'completed',
      ),
      const FavoriteItineraryModel(
        id: '2',
        title: 'Khám phá Đà Lạt mộng mơ',
        location: 'Đà Lạt',
        days: 3,
        participantCount: 1,
        status: 'completed',
      ),
    ];
  }

  @override
  Future<List<FavoritePlaceModel>> getFavoritePlaces({
    int page = 1,
    int limit = 5,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return [
      const FavoritePlaceModel(
        id: '1',
        name: 'Cầu Vàng, Đà Nẵng',
        city: 'Đà Nẵng',
        image: 'https://hellodanang.vn/wp-content/uploads/2024/09/cau-vang-bieu-tuong-kien-truc-an-tuong-tai-da-nang-1.jpg',
        rating: 4.8,
        reviewCount: 320,
      ),
      const FavoritePlaceModel(
        id: '2',
        name: 'Phố cổ Hội An',
        city: 'Hội An',
        image: 'https://lalago.vn/wp-content/uploads/2025/08/pho-co-hoi-an-ve-dem-3.jpg',
        rating: 4.9,
        reviewCount: 450,
      ),
    ];
  }
}
