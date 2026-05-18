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
  Future<ExploreHomePayload> getExploreHome();
  Future<List<CityRestaurant>> getRestaurants({int limit = 5});
  Future<List<TripSuggestionModel>> getPublicSuggestions({int limit = 50});
  Future<List<DestinationModel>> getFeaturedDestinations({int limit = 50});
  Future<List<CityRestaurant>> getRestaurantsByCategories({
    required List<String> categories,
    int limitPerCategory = 50,
  });
  Future<List<CityHotel>> getHotelsByCategories({
    required List<String> categories,
    int limitPerCategory = 50,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
/// Mock — simulates API with picsum.photos image URLs.
// ─────────────────────────────────────────────────────────────────────────────
class MockHomeDataSource implements HomeDataSource {
  @override
  Future<ExploreHomePayload> getExploreHome() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return ExploreHomePayload(
      suggestions: [
        TripSuggestionModel(id: 'trip-001', title: 'Kỳ nghỉ Phú Quốc tuyệt phẩm', days: '3 ngày', location: 'Phú Quốc', views: '2.4k', likes: '512', imageUrl: 'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?w=600&q=80', placeholderColor: 0xFF4A90D9),
        TripSuggestionModel(id: 'trip-002', title: 'Du lịch Hà Nội Hà Tây', days: '4 ngày', location: 'Hà Nội', views: '1.8k', likes: '324', imageUrl: 'https://vcdn1-dulich.vnecdn.net/2022/05/12/Hanoi2-1652338755-3632-1652338809.jpg?w=0&h=0&q=100&dpr=2&fit=crop&s=NxMN93PTvOTnHNryMx3xJw', placeholderColor: 0xFF6C9E5C),
        TripSuggestionModel(id: 'trip-003', title: 'Khám phá Quy Nhơn kỳ vĩ', days: '5 ngày', location: 'Quy Nhơn', views: '892', likes: '201', imageUrl: 'https://quynhontourist.com/wp-content/uploads/2020/11/tour-ky-co-eo-gio-1-ngay-du-lich-ky-co-quy-nhon-quy-nhon-tourist.jpg', placeholderColor: 0xFF5E7FA0),
        TripSuggestionModel(id: 'trip-004', title: 'Khám phá Đà Lạt mộng mơ', days: '3 ngày', location: 'Đà Lạt', views: '1.1k', likes: '287', imageUrl: 'https://samtenhills.vn/wp-content/uploads/2024/01/top-20-cac-diem-du-lich-da-lat-1024x576.jpg', placeholderColor: 0xFF7D5E92),
      ],
      destinations: [
        DestinationModel(id: 'dest-001', name: 'Đỉnh Fansipan', imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS1yCd0xZihK46J355FPzH8jZBXlnRRx-rzWw&s', placeholderColor: 0xFF4A8C5C),
        DestinationModel(id: 'dest-002', name: 'Phố cổ Hội An', imageUrl: 'https://lalago.vn/wp-content/uploads/2025/08/pho-co-hoi-an-ve-dem-3.jpg', placeholderColor: 0xFF8B7355),
        DestinationModel(id: 'dest-003', name: 'Thung lũng Tình Yêu', imageUrl: 'https://res.klook.com/images/fl_lossy.progressive,q_65/c_fill,w_1200,h_630/w_80,x_15,y_15,g_south_west,l_Klook_water_br_trans_yhcmh3/activities/t8ojjwnqqzgxuqr80k2o/V%C3%A9ThamQuanThungL%C5%A9ngT%C3%ACnhY%C3%AAu%E1%BB%9F%C4%90%C3%A0L%E1%BA%A1t-KlookVi%E1%BB%87tNam.jpg', placeholderColor: 0xFF3D7A5E),
        DestinationModel(id: 'dest-004', name: 'Vịnh Hạ Long', imageUrl: 'https://www.dulichhalong.net/wp-content/uploads/2020/07/Vinh-Ha-Long-Quang-Ninh.jpg', placeholderColor: 0xFF2E6B8A),
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
        const CityHotel(id: 'hotel-001', name: 'Inter Phu Quoc', rating: 4.9, reviewCount: 1300, price: '2.500.000đ', imageUrl: 'https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=400&q=80'),
        const CityHotel(id: 'hotel-002', name: 'JW Marriott', rating: 4.8, reviewCount: 980, price: '3.200.000đ', imageUrl: 'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=400&q=80'),
        const CityHotel(id: 'hotel-003', name: 'Pullman Vung Tau', rating: 4.7, reviewCount: 760, price: '2.100.000đ', imageUrl: 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=400&q=80'),
        const CityHotel(id: 'hotel-004', name: 'Vinpearl Nha Trang', rating: 4.9, reviewCount: 1540, price: '1.900.000đ', imageUrl: 'https://du-lich.chudu24.com/f/m/2306/16/vinpearl-nha-trang-resort-3.jpg?w=800&h=500'),
      ],
      currentItinerary: ItineraryEntity(
        id: 'itin-001',
        title: 'Sài Gòn 3N2Đ',
        startDate: DateTime(2026, 4, 10),
        endDate: DateTime(2026, 4, 12),
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
      CityRestaurant(
        id: 'res-003',
        name: 'Bún Chả Hương Liên',
        imageUrl: 'https://kenh14cdn.com/zoom/594_371/203336854389633024/2024/3/21/photo1711023527181-17110235273471578523867.jpg',
        rating: 4.9,
        reviewCount: 2100,
        address: 'Lê Văn Hưu, Hà Nội',
        status: 'Đang mở cửa',
      ),
    ].take(limit).toList();
  }

  @override
  Future<List<TripSuggestionModel>> getPublicSuggestions({int limit = 50}) async {
    final payload = await getExploreHome();
    return payload.suggestions.take(limit).toList();
  }

  @override
  Future<List<DestinationModel>> getFeaturedDestinations({int limit = 50}) async {
    final payload = await getExploreHome();
    return payload.destinations.take(limit).toList();
  }

  @override
  Future<List<CityRestaurant>> getRestaurantsByCategories({
    required List<String> categories,
    int limitPerCategory = 50,
  }) async {
    return getRestaurants(limit: limitPerCategory);
  }

  @override
  Future<List<CityHotel>> getHotelsByCategories({
    required List<String> categories,
    int limitPerCategory = 50,
  }) async {
    final payload = await getExploreHome();
    return payload.hotels.take(limitPerCategory).toList();
  }

}

// ─────────────────────────────────────────────────────────────────────────────
/// Remote datasource for Explore screen.
// ─────────────────────────────────────────────────────────────────────────────
class RemoteHomeDataSource implements HomeDataSource {
  final DioClient _client;

  RemoteHomeDataSource(this._client);

  @override
  Future<ExploreHomePayload> getExploreHome() async {
    final touristId = await AuthUtils.requireCurrentUserId();

    final response = await _client.dio.get(
      '/explore/home',
      queryParameters: {'tourist_id': touristId},
    );

    final mapped = _mapExploreHome(response.data as Map<String, dynamic>);

    // If backend returns no current_itinerary (server may provide a separate
    // endpoint to fetch it), try to request it explicitly so the UI can show
    // "Lịch trình của tôi" when available.
    if (mapped.currentItinerary == null) {
      try {
        final curResp = await _client.dio.get('/explore/current', queryParameters: {'tourist_id': touristId});
        if (curResp.data != null) {
          final curJson = curResp.data as Map<String, dynamic>;
          final ci = _mapCurrentItinerary(curJson['data'] ?? curJson);
          return ExploreHomePayload(
            suggestions: mapped.suggestions,
            destinations: mapped.destinations,
            restaurants: mapped.restaurants,
            hotels: mapped.hotels,
            currentItinerary: ci,
          );
        }
      } catch (_) {
        // ignore and return original mapped payload
      }
    }

    return mapped;
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
    final creatorId = (json['creator_id'] ?? '').toString();
    final creatorName = (json['creator_name'] ?? 'Traveler').toString().trim();

    return TripSuggestionModel(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? 'Lịch trình gợi ý').toString(),
      authorName: creatorName.isEmpty ? 'Traveler' : creatorName,
      authorAvatar:
          creatorId.isEmpty ? '' : 'https://i.pravatar.cc/100?u=$creatorId',
      days: '$days ngày',
      location: (json['location'] ?? 'Không xác định').toString(),
      views: ((json['participant_count'] as num?)?.toInt() ?? 0).toString(),
      likes: ((json['participant_count'] as num?)?.toInt() ?? 0).toString(),
      imageUrl: primaryImage.isEmpty ? null : primaryImage,
      imageGallery: imageGallery,
      placeholderColor: 0xFF4A90D9,
    );
  }

  DestinationModel _mapPlace(Map<String, dynamic> json, bool isHotel) {
    return DestinationModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Không xác định').toString(),
      imageUrl: (json['image'] ?? '').toString(),
      placeholderColor: isHotel ? 0xFFD4C5B0 : 0xFF4A8C5C,
    );
  }

  CityHotel _mapHotel(Map<String, dynamic> json) {
    return CityHotel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Khách sạn').toString(),
      imageUrl: (json['image'] ?? '').toString(),
      rating: ((json['rating'] as num?) ?? 0).toDouble(),
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      // Try to read a numeric or formatted price from payload. Fall back to 0đ
      price: () {
        final rawPrice = (json['price'] ?? json['min_price'] ?? '').toString().trim();
        final priceValue = rawPrice.isNotEmpty ? rawPrice : '0đ';
        return priceValue;
      }(),
      address: (json['city'] ?? json['province'] ?? json['location'] ?? '').toString(),
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
      case 'uncompleted':
        return ItineraryStatus.upcoming;
      case 'ongoing':
        return ItineraryStatus.ongoing;
      case 'completed':
        return ItineraryStatus.completed;
      default:
        return ItineraryStatus.draft;
    }
  }

  @override
  Future<List<TripSuggestionModel>> getPublicSuggestions({int limit = 50}) async {
    final response = await _client.dio.get(
      '/explore/itineraries/public',
      queryParameters: {'page': 1, 'limit': limit},
    );

    final data = response.data as Map<String, dynamic>;
    final items = _asList(data['data']);
    return items.map(_mapSuggestion).toList();
  }

  @override
  Future<List<DestinationModel>> getFeaturedDestinations({int limit = 50}) async {
    final response = await _client.dio.get(
      '/explore/cities',
      queryParameters: {'page': 1, 'limit': limit},
    );

    final data = response.data as Map<String, dynamic>;
    final items = _asList(data['data']);
    return items.map((item) => _mapPlace(item, false)).toList();
  }

  Future<List<Map<String, dynamic>>> _getPlacesByCategory({
    required String category,
    required int limit,
  }) async {
    final response = await _client.dio.get(
      '/explore/places',
      queryParameters: {
        'category': category,
        'page': 1,
        'limit': limit,
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
      status: 'Đang mở cửa',
      cuisine: 'vietnamese',
      priceLevel: 'mid_range',
      amenities: const <String>[],
    );
  }

  @override
  Future<List<CityRestaurant>> getRestaurantsByCategories({
    required List<String> categories,
    int limitPerCategory = 50,
  }) async {
    final groups = await Future.wait<List<Map<String, dynamic>>>(
      categories.map((category) async {
        try {
          return await _getPlacesByCategory(
            category: category,
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
    int limitPerCategory = 50,
  }) async {
    final groups = await Future.wait<List<Map<String, dynamic>>>(
      categories.map((category) async {
        try {
          return await _getPlacesByCategory(
            category: category,
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