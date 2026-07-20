import 'package:dio/dio.dart' show Options;
import 'package:travel_advisor_mobile/features/city_detail/domain/entities/city_entities.dart';
import 'package:travel_advisor_mobile/core/network/dio_client.dart';
import 'package:travel_advisor_mobile/core/utils/auth_utils.dart';
import 'package:travel_advisor_mobile/features/home/data/models/destination_model.dart';
import 'package:travel_advisor_mobile/features/home/data/models/trip_suggestion_model.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_entity.dart';

class ExploreHomePayload {
  final List<TripSuggestionModel> suggestions;
  final List<DestinationModel> destinations;
  final List<CityRestaurant> restaurants;
  final List<CityHotel> hotels;
  final ItineraryEntity? currentItinerary;

  const ExploreHomePayload({
    required this.suggestions,
    required this.destinations,
    required this.restaurants,
    required this.hotels,
    required this.currentItinerary,
  });
}

/// Contract for home screen data.
abstract class HomeDataSource {
  Future<ExploreHomePayload> getExploreHome({bool forceRefresh = false});
  Future<List<CityRestaurant>> getRestaurants({int limit = 5});
  Future<List<TripSuggestionModel>> getPublicSuggestions({int page = 1, int limit = 50});
  Future<List<DestinationModel>> getFeaturedDestinations({int page = 1, int limit = 50});
  Future<List<CityRestaurant>> getRestaurantsByCategories({
    required List<String> categories,
    int page = 1,
    int limitPerCategory = 50,
  });
  Future<List<CityHotel>> getHotelsByCategories({
    required List<String> categories,
    int page = 1,
    int limitPerCategory = 50,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
/// Mock — simulates API with picsum.photos image URLs.
// ─────────────────────────────────────────────────────────────────────────────
class MockHomeDataSource implements HomeDataSource {
  @override
  Future<ExploreHomePayload> getExploreHome({bool forceRefresh = false}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return ExploreHomePayload(
      suggestions: [
        const TripSuggestionModel(
          id: 'trip-001',
          title: 'Kỳ nghỉ Phú Quốc tuyệt phẩm: Nắng vàng & Biển xanh',
          authorName: 'Hoàng Nam',
          authorAvatar: 'https://i.pravatar.cc/150?u=nam',
          days: '3 ngày',
          location: 'Phú Quốc',
          views: '5.2k',
          likes: '1.2k',
          imageUrl: 'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?w=800&q=80',
          imageGallery: [
            'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?w=800&q=80',
            'https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=800&q=80',
          ],
          placeholderColor: 0xFF4A90D9,
        ),
        const TripSuggestionModel(
          id: 'trip-002',
          title: 'Hành trình di sản: Huế - Đà Nẵng - Hội An',
          authorName: 'Minh Thư',
          authorAvatar: 'https://i.pravatar.cc/150?u=thu',
          days: '4 ngày',
          location: 'Miền Trung',
          views: '3.8k',
          likes: '850',
          imageUrl: 'https://images.unsplash.com/photo-1555921015-5532091f6026?w=800&q=80',
          imageGallery: [
            'https://images.unsplash.com/photo-1555921015-5532091f6026?w=800&q=80',
            'https://lalago.vn/wp-content/uploads/2025/08/pho-co-hoi-an-ve-dem-3.jpg',
          ],
          placeholderColor: 0xFF6C9E5C,
        ),
        const TripSuggestionModel(
          id: 'trip-003',
          title: 'Sapa mùa lúa chín: Chinh phục đỉnh Fansipan',
          authorName: 'Việt Hoàng',
          authorAvatar: 'https://i.pravatar.cc/150?u=hoang',
          days: '3 ngày',
          location: 'Lào Cai',
          views: '4.5k',
          likes: '920',
          imageUrl: 'https://images.unsplash.com/photo-1508804185872-d7badad00f7d?w=800&q=80',
          imageGallery: [
            'https://images.unsplash.com/photo-1508804185872-d7badad00f7d?w=800&q=80',
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS1yCd0xZihK46J355FPzH8jZBXlnRRx-rzWw&s',
          ],
          placeholderColor: 0xFF5E7FA0,
        ),
        const TripSuggestionModel(
          id: 'trip-004',
          title: 'Khám phá Ninh Bình: Hạ Long trên cạn',
          authorName: 'Thanh Vân',
          authorAvatar: 'https://i.pravatar.cc/150?u=van',
          days: '2 ngày',
          location: 'Ninh Bình',
          views: '2.9k',
          likes: '640',
          imageUrl: 'https://images.unsplash.com/photo-1599708153386-62e2d36d4bc3?w=800&q=80',
          imageGallery: [
            'https://images.unsplash.com/photo-1599708153386-62e2d36d4bc3?w=800&q=80',
          ],
          placeholderColor: 0xFF7D5E92,
        ),
        const TripSuggestionModel(
          id: 'trip-005',
          title: 'Mênh mông sông nước Cần Thơ',
          authorName: 'Đức Phúc',
          authorAvatar: 'https://i.pravatar.cc/150?u=phuc',
          days: '2 ngày',
          location: 'Cần Thơ',
          views: '1.5k',
          likes: '310',
          imageUrl: 'https://images.unsplash.com/photo-1583417319070-4a69db38a482?w=800&q=80',
          placeholderColor: 0xFF9E7C5C,
        ),
      ],
      destinations: [
        const DestinationModel(
          id: 'dest-001',
          name: 'Đà Lạt',
          imageUrl: 'https://samtenhills.vn/wp-content/uploads/2024/01/top-20-cac-diem-du-lich-da-lat-1024x576.jpg',
          placeholderColor: 0xFF4A8C5C,
        ),
        const DestinationModel(
          id: 'dest-002',
          name: 'Hội An',
          imageUrl: 'https://lalago.vn/wp-content/uploads/2025/08/pho-co-hoi-an-ve-dem-3.jpg',
          placeholderColor: 0xFF8B7355,
        ),
        const DestinationModel(
          id: 'dest-003',
          name: 'Hạ Long',
          imageUrl: 'https://www.dulichhalong.net/wp-content/uploads/2020/07/Vinh-Ha-Long-Quang-Ninh.jpg',
          placeholderColor: 0xFF3D7A5E,
        ),
        const DestinationModel(
          id: 'dest-004',
          name: 'Ninh Bình',
          imageUrl: 'https://images.unsplash.com/photo-1599708153386-62e2d36d4bc3?w=800&q=80',
          placeholderColor: 0xFF2E6B8A,
        ),
        const DestinationModel(
          id: 'dest-005',
          name: 'Hà Giang',
          imageUrl: 'https://images.unsplash.com/photo-1508804185872-d7badad00f7d?w=800&q=80',
          placeholderColor: 0xFF5C8B73,
        ),
      ],
      restaurants: const [
        CityRestaurant(
          id: 'res-001',
          name: 'Cơm tấm Ba Ghiền',
          imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400&q=80',
          rating: 4.8,
          reviewCount: 1200,
          address: 'Đặng Văn Ngữ, Phú Nhuận',
          status: 'Đang mở cửa',
        ),
        CityRestaurant(
          id: 'res-002',
          name: 'Phở Hòa Pasteur',
          imageUrl: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400&q=80',
          rating: 4.7,
          reviewCount: 850,
          address: 'Pasteur, Quận 3',
          status: 'Đang mở cửa',
        ),
      ],
      hotels: [
        const CityHotel(
          id: 'hotel-reverie',
          name: 'The Reverie Saigon',
          rating: 5.0,
          reviewCount: 2800,
          price: '8.500.000đ',
          imageUrl: 'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=800&q=80',
        ),
        const CityHotel(
          id: 'hotel-001',
          name: 'InterContinental Phu Quoc',
          rating: 4.9,
          reviewCount: 1540,
          price: '4.200.000đ',
          imageUrl: 'https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=400&q=80',
        ),
        const CityHotel(
          id: 'hotel-002',
          name: 'JW Marriott Hotel Hanoi',
          rating: 4.8,
          reviewCount: 1200,
          price: '3.800.000đ',
          imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=400&q=80',
        ),
      ],
      currentItinerary: ItineraryEntity(
        id: 'itin-001',
        title: 'Hành trình khám phá Sài Gòn 3N2Đ',
        startDate: DateTime(2026, 5, 20),
        endDate: DateTime(2026, 5, 22),
        durationDays: 3,
        status: ItineraryStatus.upcoming,
      ),
    );
  }

  @override
  Future<List<CityRestaurant>> getRestaurants({int limit = 5}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const [
      CityRestaurant(
        id: 'res-001',
        name: 'Cơm Tấm Ba Ghiền',
        imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400&q=80',
        rating: 4.8,
        reviewCount: 2500,
        address: '84 Đặng Văn Ngữ, Phú Nhuận, TP. HCM',
        status: 'Đang mở cửa',
      ),
      CityRestaurant(
        id: 'res-002',
        name: 'Phở Thìn Lò Đúc',
        imageUrl: 'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=400&q=80',
        rating: 4.7,
        reviewCount: 1800,
        address: '13 Lò Đúc, Hai Bà Trưng, Hà Nội',
        status: 'Đang mở cửa',
      ),
      CityRestaurant(
        id: 'res-003',
        name: 'Bún Chả Hương Liên (Obama)',
        imageUrl: 'https://kenh14cdn.com/zoom/594_371/203336854389633024/2024/3/21/photo1711023527181-17110235273471578523867.jpg',
        rating: 4.9,
        reviewCount: 3200,
        address: '24 Lê Văn Hưu, Hai Bà Trưng, Hà Nội',
        status: 'Đang mở cửa',
      ),
      CityRestaurant(
        id: 'res-004',
        name: 'Pizza 4P\'s Ben Thanh',
        imageUrl: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400&q=80',
        rating: 4.9,
        reviewCount: 5000,
        address: '8 Thủ Khoa Huân, Quận 1, TP. HCM',
        status: 'Đang mở cửa',
      ),
    ].take(limit).toList();
  }

  @override
  Future<List<TripSuggestionModel>> getPublicSuggestions({int page = 1, int limit = 50}) async {
    final payload = await getExploreHome();
    final start = (page - 1) * limit;
    return payload.suggestions.skip(start).take(limit).toList();
  }

  @override
  Future<List<DestinationModel>> getFeaturedDestinations({int page = 1, int limit = 50}) async {
    final payload = await getExploreHome();
    final start = (page - 1) * limit;
    return payload.destinations.skip(start).take(limit).toList();
  }

  @override
  Future<List<CityRestaurant>> getRestaurantsByCategories({
    required List<String> categories,
    int page = 1,
    int limitPerCategory = 50,
  }) async {
    final payload = await getExploreHome();
    final start = (page - 1) * limitPerCategory;
    return payload.restaurants.skip(start).take(limitPerCategory).toList();
  }

  @override
  Future<List<CityHotel>> getHotelsByCategories({
    required List<String> categories,
    int page = 1,
    int limitPerCategory = 50,
  }) async {
    final payload = await getExploreHome();
    final start = (page - 1) * limitPerCategory;
    return payload.hotels.skip(start).take(limitPerCategory).toList();
  }

}

// ─────────────────────────────────────────────────────────────────────────────
/// Remote datasource for Explore screen.
// ─────────────────────────────────────────────────────────────────────────────
class RemoteHomeDataSource implements HomeDataSource {
  final DioClient _client;

  RemoteHomeDataSource(this._client);

  @override
  Future<ExploreHomePayload> getExploreHome({bool forceRefresh = false}) async {
    final touristId = await AuthUtils.requireCurrentUserId();
    final opts = forceRefresh ? _client.forceRefreshOptions : null;

    // Fire both requests in parallel — eliminates the sequential penalty when
    // /explore/home returns no current_itinerary and the fallback is needed.
    final homeFuture = _client.dio.get(
      '/explore/home',
      queryParameters: {'tourist_id': touristId},
      options: opts,
    );
    final curFuture = _fetchCurrentItinerary(touristId, opts);

    final homeResp = await homeFuture;
    final mapped = _mapExploreHome(homeResp.data as Map<String, dynamic>);

    if (mapped.currentItinerary == null) {
      final curData = await curFuture;
      if (curData != null) {
        final ci = _mapCurrentItinerary(curData['data'] ?? curData);
        return ExploreHomePayload(
          suggestions: mapped.suggestions,
          destinations: mapped.destinations,
          restaurants: mapped.restaurants,
          hotels: mapped.hotels,
          currentItinerary: ci,
        );
      }
    }

    return mapped;
  }

  Future<Map<String, dynamic>?> _fetchCurrentItinerary(
    String touristId,
    Options? opts,
  ) async {
    try {
      // Always bypass client cache so the itinerary card reflects the latest
      // DB state even when the home response was served from cache.
      final r = await _client.dio.get(
        '/explore/current',
        queryParameters: {'tourist_id': touristId},
        options: _client.forceRefreshOptions,
      );
      return r.data is Map<String, dynamic> ? r.data as Map<String, dynamic> : null;
    } catch (_) {
      return null;
    }
  }

  ExploreHomePayload _mapExploreHome(Map<String, dynamic> json) {
    final suggestionJson = _asList(json['suggestion_itineraries']);
    final destinationsJson = _asList(json['featured_places']);
    final restaurantsJson = _asList(json['restaurants']);
    final hotelsJson = _asList(json['hotels']);

    return ExploreHomePayload(
      suggestions: suggestionJson.map(_mapSuggestion).toList(),
      destinations: destinationsJson.map((item) => _mapPlace(item, false)).toList(),
      restaurants: restaurantsJson.map(_mapRestaurant).toList(),
      hotels: hotelsJson.map(_mapHotel).toList(),
      currentItinerary: _mapCurrentItinerary(json['current_itinerary']),
    );
  }

  List<Map<String, dynamic>> _asList(dynamic raw) {
    if (raw is! List) {
      return const [];
    }

    return raw.whereType<Map<String, dynamic>>().toList();
  }

  List<String> _toStringList(dynamic raw) {
    if (raw is! List) {
      return const <String>[];
    }

    return raw
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  TripSuggestionModel _mapSuggestion(Map<String, dynamic> json) {
    final days = (json['days'] as num?)?.toInt() ?? 0;
    final imageGallery = _toStringList(json['image_gallery']);
    final primaryImage = (json['image'] ?? '').toString();
    final creatorName = (json['creator_name'] ?? 'Traveler').toString().trim();
    final creatorAvatar = (json['creator_avatar'] ?? json['author_avatar'] ?? '').toString().trim();

    final favoriteCount = (json['favorite_count'] as num?)?.toInt() ?? 0;
    final avgRating = ((json['average_rating'] as num?) ?? 0).toDouble();
    final travelType = (json['trip_intent'] ?? '').toString();
    return TripSuggestionModel(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? 'Lịch trình gợi ý').toString(),
      authorName: creatorName.isEmpty ? 'Traveler' : creatorName,
      authorAvatar: creatorAvatar,
      days: '$days ngày',
      location: (json['location'] ?? 'Không xác định').toString(),
      views: ((json['participant_count'] as num?)?.toInt() ?? 0).toString(),
      likes: favoriteCount.toString(),
      favoriteCount: favoriteCount,
      rating: avgRating,
      travelType: travelType,
      imageUrl: primaryImage.isEmpty ? null : primaryImage,
      imageGallery: imageGallery,
      placeholderColor: 0xFF4A90D9,
      isFavorite: json['is_favorite'] == true || json['isFavorite'] == true,
    );
  }

  DestinationModel _mapPlace(Map<String, dynamic> json, bool isHotel) {
    final imageUrl = (json['image_url'] ?? json['image'] ?? '').toString();
    return DestinationModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Không xác định').toString(),
      imageUrl: imageUrl,
      placeholderColor: isHotel ? 0xFFD4C5B0 : 0xFF4A8C5C,
      averageRating: ((json['rating'] as num?) ?? 0).toDouble(),
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
    );
  }

  double? _readHotelPrice(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw > 0 ? raw.toDouble() : null;

    final value = raw.toString().trim();
    if (value.isEmpty || value.toLowerCase().contains('liên hệ')) return null;
    final numeric = double.tryParse(value);
    if (numeric != null) return numeric > 0 ? numeric : null;

    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    final parsed = double.tryParse(digits);
    return parsed != null && parsed > 0 ? parsed : null;
  }

  String _formatVndPrice(double value) {
    final digits = value.round().toString();
    return '${digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    )}đ';
  }

  CityHotel _mapHotel(Map<String, dynamic> json) {
    final minPrice = _readHotelPrice(
      json['min_price'] ??
          json['priceValue'] ??
          json['price_value'] ??
          json['price'],
    );
    return CityHotel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Khách sạn').toString(),
      imageUrl: (json['image'] ?? '').toString(),
      rating: ((json['rating'] as num?) ?? 0).toDouble(),
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      price: minPrice == null ? 'Liên hệ' : _formatVndPrice(minPrice),
      priceValue: minPrice ?? 0,
      address: (json['city'] ?? json['province'] ?? json['location'] ?? '').toString(),
      status: () {
        final s = (json['status'] ?? '').toString().trim();
        return s == 'Chưa có giờ mở cửa' ? '' : s;
      }(),
      isFavorite: json['is_favorite'] == true || json['isFavorite'] == true,
    );
  }

  ItineraryEntity? _mapCurrentItinerary(dynamic raw) {
    if (raw is! Map<String, dynamic>) {
      return null;
    }

    final startDate = _parseDateFromRange(raw['date_range'], 0);
    final endDate = _parseDateFromRange(raw['date_range'], 1);

    return ItineraryEntity(
      id: (raw['id'] ?? '').toString(),
        title: ((raw['description'] as String?)?.trim().isNotEmpty ?? false)
          ? (raw['description'] as String).trim()
          : (raw['title'] ?? 'Lịch trình của bạn').toString(),
      startDate: startDate,
      endDate: endDate,
      durationDays: _calcDurationDays(startDate, endDate),
      status: _mapStatus((raw['status'] ?? '').toString()),
    );
  }

  DateTime? _parseDateFromRange(dynamic dateRange, int index) {
    if (dateRange is! String || dateRange.isEmpty) {
      return null;
    }

    final parts = dateRange.split(' - ');
    if (parts.length <= index) {
      return null;
    }

    return DateTime.tryParse(parts[index].trim());
  }

  int _calcDurationDays(DateTime? start, DateTime? end) {
    if (start == null || end == null) {
      return 1;
    }

    final diff = end.difference(start).inDays + 1;
    return diff > 0 ? diff : 1;
  }

  ItineraryStatus _mapStatus(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
      case 'upcoming':
        return ItineraryStatus.upcoming;
      case 'uncompleted':
        return ItineraryStatus.uncompleted;
      case 'ongoing':
        return ItineraryStatus.ongoing;
      case 'completed':
        return ItineraryStatus.completed;
      default:
        return ItineraryStatus.draft;
    }
  }

  @override
  Future<List<TripSuggestionModel>> getPublicSuggestions({int page = 1, int limit = 50}) async {
    final response = await _client.dio.get(
      '/explore/itineraries/public',
      queryParameters: {
        'page': page,
        'limit': limit,
        'tourist_id': await AuthUtils.requireCurrentUserId(),
      },
    );

    final data = response.data as Map<String, dynamic>;
    final items = _asList(data['data']);
    return items.map(_mapSuggestion).toList();
  }

  @override
  Future<List<DestinationModel>> getFeaturedDestinations({int page = 1, int limit = 50}) async {
    final response = await _client.dio.get(
      '/explore/cities',
      queryParameters: {'page': page, 'limit': limit},
    );

    final data = response.data as Map<String, dynamic>;
    final items = _asList(data['data']);
    return items.map((item) => _mapPlace(item, false)).toList();
  }

  Future<List<Map<String, dynamic>>> _getPlacesByCategory({
    required String category,
    required int page,
    required int limit,
  }) async {
    final response = await _client.dio.get(
      '/explore/places',
      queryParameters: {
        'category': category,
        'page': page,
        'limit': limit,
        'tourist_id': await AuthUtils.requireCurrentUserId(),
        '_ts': DateTime.now().millisecondsSinceEpoch,
      },
    );

    final data = response.data as Map<String, dynamic>;
    return _asList(data['data']);
  }

  List<Map<String, dynamic>> _mergeById(List<List<Map<String, dynamic>>> groups) {
    final map = <String, Map<String, dynamic>>{};
    for (final group in groups) {
      for (final item in group) {
        final id = (item['id'] ?? '').toString();
        if (id.isEmpty || map.containsKey(id)) {
          continue;
        }
        map[id] = item;
      }
    }
    return map.values.toList();
  }

  @override
  Future<List<CityRestaurant>> getRestaurants({int limit = 5}) async {
    return getRestaurantsByCategories(
      categories: const ['ẩm thực'],
      limitPerCategory: limit,
    );
  }

  CityRestaurant _mapRestaurant(Map<String, dynamic> item) {
    return CityRestaurant(
      id: (item['id'] ?? '').toString(),
      name: (item['name'] ?? 'Nhà hàng').toString(),
      imageUrl: (item['image'] ?? '').toString(),
      rating: ((item['rating'] as num?) ?? 0).toDouble(),
      reviewCount: (item['review_count'] as num?)?.toInt() ?? 0,
      address: (item['city'] ?? '').toString(),
      // Backend trả "Chưa có giờ mở cửa" khi địa điểm thiếu dữ liệu giờ —
      // coi như không có status để card ẩn dòng này thay vì hiển thị.
      status: () {
        final s = (item['status'] ?? '').toString().trim();
        return s == 'Chưa có giờ mở cửa' ? '' : s;
      }(),
      cuisine: 'vietnamese',
      priceLevel: 'mid_range',
      amenities: const <String>[],
      isFavorite: item['is_favorite'] == true || item['isFavorite'] == true,
    );
  }

  @override
  Future<List<CityRestaurant>> getRestaurantsByCategories({
    required List<String> categories,
    int page = 1,
    int limitPerCategory = 50,
  }) async {
    final groups = await Future.wait<List<Map<String, dynamic>>>(
      categories.map((category) async {
        try {
          return await _getPlacesByCategory(
            category: category,
            page: page,
            limit: limitPerCategory,
          );
        } catch (_) {
          return const <Map<String, dynamic>>[];
        }
      }),
    );

    final merged = _mergeById(groups);
    return merged.map(_mapRestaurant).toList();
  }

  @override
  Future<List<CityHotel>> getHotelsByCategories({
    required List<String> categories,
    int page = 1,
    int limitPerCategory = 50,
  }) async {
    final groups = await Future.wait<List<Map<String, dynamic>>>(
      categories.map((category) async {
        try {
          return await _getPlacesByCategory(
            category: category,
            page: page,
            limit: limitPerCategory,
          );
        } catch (_) {
          return const <Map<String, dynamic>>[];
        }
      }),
    );

    final merged = _mergeById(groups);
    return merged.map(_mapHotel).toList();
  }
}
