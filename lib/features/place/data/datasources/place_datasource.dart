import 'package:dio/dio.dart';
import 'package:travel_advisor_mobile/core/network/dio_client.dart';
import 'package:travel_advisor_mobile/core/utils/auth_utils.dart';
import 'package:travel_advisor_mobile/features/place/domain/entities/place_food_item_entity.dart';
import 'package:travel_advisor_mobile/features/place/domain/entities/place_review_entity.dart';
import 'package:travel_advisor_mobile/features/place/data/models/place_detail_model.dart';
import 'package:travel_advisor_mobile/features/place/data/models/place_food_item_model.dart';
import 'package:travel_advisor_mobile/features/place/data/models/place_model.dart';
import 'package:travel_advisor_mobile/features/place/data/models/place_review_model.dart';

class PlaceFoodItemsPage {
  final String placeId;
  final String placeName;
  final List<PlaceFoodItemEntity> items;
  final int page;
  final int limit;
  final int total;
  final int pages;

  const PlaceFoodItemsPage({
    required this.placeId,
    required this.placeName,
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });
}

class PlaceReviewsPage {
  final String placeId;
  final String placeName;
  final double average;
  final int total;
  final Map<int, int> breakdown;
  final List<PlaceReviewEntity> items;
  final int page;
  final int limit;
  final int pages;

  const PlaceReviewsPage({
    required this.placeId,
    required this.placeName,
    required this.average,
    required this.total,
    required this.breakdown,
    required this.items,
    required this.page,
    required this.limit,
    required this.pages,
  });
}

abstract class PlaceDataSource {
  Future<PlaceDetailModel> getPlaceDetail(String id);
  Future<PlaceFoodItemsPage> getPlaceFoodItems(
    String id, {
    int page,
    int limit,
  });
  Future<PlaceReviewsPage> getPlaceReviews(
    String id, {
    String? touristId,
    int page,
    int limit,
  });
}

class MockPlaceDataSource implements PlaceDataSource {
  @override
  Future<PlaceDetailModel> getPlaceDetail(String id) async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (id == 'hotel-reverie') {
      return const PlaceDetailModel(
        id: 'hotel-reverie',
        name: 'The Reverie Saigon',
        address: '22-36 Nguyễn Huệ, Bến Nghé, Quận 1, TP. HCM',
        district: 'Quận 1',
        city: 'TP. HCM',
        rating: 5.0,
        totalReviews: 2800,
        vibes: ['Sang trọng', 'Thượng lưu', 'View đẹp'],
        images: [
          'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=800&q=80',
          'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',
        ],
        description:
            'The Reverie Saigon là khách sạn 6 sao sang trọng bậc nhất Việt Nam, nằm tại trung tâm Quận 1. Với thiết kế mang đậm phong cách Ý cổ điển và tầm nhìn panorama ra toàn cảnh thành phố.',
        openingHours: '00:00',
        closingHours: '23:59',
        openHourCompressed:
            '{"Monday":[["00:00:00","23:59:00"]],"Tuesday":[["00:00:00","23:59:00"]],"Wednesday":[["00:00:00","23:59:00"]],"Thursday":[["00:00:00","23:59:00"]],"Friday":[["00:00:00","23:59:00"]],"Saturday":[["00:00:00","23:59:00"]],"Sunday":[["00:00:00","23:59:00"]]}',
        phone: '(028) 3823 6688',
        isFavorite: true,
        latitude: 10.7752,
        longitude: 106.7041,
        typeName: 'Khách sạn & Resort',
        foodItems: const [],
        reviews: [],
        relatedPlaces: [],
      );
    }

    return PlaceDetailModel(
      id: 'nh-001',
      name: 'Nhà hát Thành phố Hồ Chí Minh',
      address: '7 Công Trường Lam Sơn, Quận 1, TP. HCM',
      district: 'Quận 1',
      city: 'TP. HCM',
      rating: 4.5,
      totalReviews: 1248,
      vibes: ['Văn hóa - lịch sử', 'Tham quan - chụp ảnh'],
      images: [
        'https://kyhoatourist.com.vn/uploadwb/image/tintuc/nha-hat-lon-2.jpg',
        'https://static.vinwonders.com/production/nha-hat-thanh-pho-1.jpg',
        'https://res.klook.com/images/fl_lossy.progressive,q_65/c_fill,w_1200,h_811/w_74,x_13,y_13,g_south_west,l_Klook_water_br_trans_yhcmh3/activities/i64sjejsothrtuqz43ap/V%C3%A9%C3%80%E1%BB%90Show%E1%BB%9ENh%C3%A0H%C3%A1tTh%C3%A0nhPh%E1%BB%91.jpg',
      ],
      description:
          'Nhà Hát Lớn Thành Phố - Thăm quan & chụp ảnh. Sân khấu tại 7 Công Trường Lam Sơn, Quận 1, TP. HCM. Giá bình quân đầu người: 80.000đ - 350.000đ. Đây là công trình kiến trúc đặc sắc của Sài Gòn.',
      openingHours: '10:00',
      closingHours: '23:00',
      openHourCompressed:
          '{"Monday":[["10:00:00","23:00:00"]],"Tuesday":[["10:00:00","23:00:00"]],"Wednesday":[["10:00:00","23:00:00"]],"Thursday":[["10:00:00","23:00:00"]],"Friday":[["10:00:00","23:00:00"]],"Saturday":[["10:00:00","23:00:00"]],"Sunday":[]}',
      phone: '(028) 38 299 919',
      isFavorite: true,
      latitude: 10.7766,
      longitude: 106.7032,
      typeName: 'Văn hóa - lịch sử',
      foodItems: const [],
      reviews: [
        PlaceReviewModel(
          id: 'rv-001',
          userName: 'Minh Anh Trần',
          userAvatar: 'https://i.pravatar.cc/150?u=minhanh',
          rating: 5,
          timeAgo: '3 ngày trước',
          reviewText:
              'Kiến trúc rất đẹp và cổ kính, buổi tối lên đèn lung linh lắm, cực kỳ hợp để check-in sống ảo.',
          reviewImages: [
            'https://images.unsplash.com/photo-1583417319070-4a69db38a482?w=400&q=80',
          ],
        ),
        PlaceReviewModel(
          id: 'rv-002',
          userName: 'Thế Hùng',
          userAvatar: 'https://i.pravatar.cc/150?u=thehung',
          rating: 4,
          timeAgo: '1 tuần trước',
          reviewText:
              'Địa điểm ngay trung tâm, dễ tìm. Tuy nhiên khá đông đúc vào cuối tuần.',
        ),
      ],
      relatedPlaces: [
        PlaceModel(
          id: 'pl-related-001',
          name: 'Bảo tàng Mỹ thuật',
          imageUrl:
              'https://cdn2.fptshop.com.vn/unsafe/1920x0/filters:format(webp):quality(75)/bao_tang_my_thuat_2_5830af02a8.png',
          rating: 4.6,
          district: 'Quận 1',
          city: 'TP. HCM',
        ),
        PlaceModel(
          id: 'pl-related-002',
          name: 'Chùa Ngọc Hoàng',
          imageUrl:
              'https://images.unsplash.com/photo-1528127269322-539801943592?w=400&q=80',
          rating: 4.7,
          district: 'Quận 3',
          city: 'TP. HCM',
        ),
      ],
    );
  }

  @override
  Future<PlaceFoodItemsPage> getPlaceFoodItems(
    String id, {
    int page = 1,
    int limit = 10,
  }) async {
    final detail = await getPlaceDetail(id);
    final items = detail.foodItems.map((item) => item.toEntity()).toList();
    final offset = (page - 1) * limit;
    return PlaceFoodItemsPage(
      placeId: id,
      placeName: detail.name,
      items: items.skip(offset).take(limit).toList(),
      page: page,
      limit: limit,
      total: items.length,
      pages: items.isEmpty ? 0 : (items.length / limit).ceil(),
    );
  }

  @override
  Future<PlaceReviewsPage> getPlaceReviews(
    String id, {
    String? touristId,
    int page = 1,
    int limit = 10,
  }) async {
    final detail = await getPlaceDetail(id);
    final items = detail.reviews.map((item) => item.toEntity()).toList();
    final offset = (page - 1) * limit;
    final breakdown = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final review in items) {
      final rating = review.rating.round().clamp(1, 5);
      breakdown[rating] = (breakdown[rating] ?? 0) + 1;
    }

    return PlaceReviewsPage(
      placeId: id,
      placeName: detail.name,
      average: items.isEmpty
        ? detail.rating
        : items.fold<double>(0.0, (sum, item) => sum + item.rating) /
          items.length,
      total: items.length,
      breakdown: breakdown,
      items: items.skip(offset).take(limit).toList(),
      page: page,
      limit: limit,
      pages: items.isEmpty ? 0 : (items.length / limit).ceil(),
    );
  }
}

class RemotePlaceDataSource implements PlaceDataSource {
  final DioClient _client;

  RemotePlaceDataSource(this._client);

  List<Map<String, dynamic>> _asList(dynamic raw) {
    if (raw is! List) {
      return const [];
    }
    return raw.whereType<Map<String, dynamic>>().toList();
  }

  @override
  Future<PlaceDetailModel> getPlaceDetail(String id) async {
    final touristId = await AuthUtils.getCurrentUserId();

    try {
      final response = await _client.dio.get(
        '/places/$id',
        queryParameters: {
          if (touristId != null && touristId.isNotEmpty)
            'tourist_id': touristId,
        },
      );

      return _mapPlaceDetail(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final message = e.response?.data is Map<String, dynamic>
          ? ((e.response?.data as Map<String, dynamic>)['message'] ?? e.message)
          : e.message;
      throw Exception('Không tải được chi tiết địa điểm: $message');
    }
  }

  PlaceDetailModel _mapPlaceDetail(Map<String, dynamic> json) {
    final images = _toStringList(json['images']);
    final primaryImage = (json['image_url'] ?? '').toString();
    final gallery = images.isNotEmpty
        ? images
        : (primaryImage.isNotEmpty ? <String>[primaryImage] : <String>[]);

    final reviewInfo =
        (json['reviews'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    final reviewList =
        (reviewInfo['list'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(_mapReview)
            .toList();
    final reviewBreakdown = _mapBreakdown(reviewInfo['breakdown']);

    final related =
        (json['related_places'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(_mapRelatedPlace)
            .toList();
    final foodItems =
      (json['food_items'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(_mapFoodItem)
        .toList();

    return PlaceDetailModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Địa điểm').toString(),
      address: (json['address'] ?? '').toString(),
      district: (json['district'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      rating: ((json['rating'] as num?) ?? 0).toDouble(),
      totalReviews:
          (json['review_count'] as num?)?.toInt() ??
          (reviewInfo['total'] as num?)?.toInt() ??
          0,
      typeName: json['type_name']?.toString(),
      vibes: _toStringList(json['vibes']),
      images: gallery,
      description: (json['description'] ?? '').toString(),
      openingHours: (json['open_time'] ?? '').toString(),
      closingHours: (json['close_time'] ?? '').toString(),
      openHourCompressed: json['open_hour_compressed']?.toString(),
      phone: (json['phone'] ?? '').toString(),
      foodItems: foodItems,
      reviews: reviewList,
      reviewBreakdown: reviewBreakdown,
      relatedPlaces: related,
      isFavorite: json['is_favorite'] == true,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  PlaceReviewModel _mapReview(Map<String, dynamic> json) {
    final avatarSeed = (json['user_name'] ?? json['id'] ?? 'anonymous')
        .toString();

    return PlaceReviewModel(
      id: (json['id'] ?? '').toString(),
      userName: (json['user_name'] ?? 'Ẩn danh').toString(),
      userAvatar: 'https://i.pravatar.cc/150?u=$avatarSeed',
      rating: ((json['rating'] as num?) ?? 0).toDouble(),
      timeAgo: (json['time_ago'] ?? '').toString().trim().isNotEmpty
          ? (json['time_ago'] ?? '').toString()
          : _toTimeAgo((json['created_at'] ?? '').toString()),
      reviewText: (json['content'] ?? '').toString(),
      provider: (json['provider'] ?? '').toString().trim().isEmpty
          ? null
          : (json['provider'] ?? '').toString(),
      status: (json['status'] ?? 'approved').toString(),
      reviewImages: const <String>[],
    );
  }

  Map<int, int> _mapBreakdown(dynamic raw) {
    final breakdown = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    if (raw is! Map) {
      return breakdown;
    }

    for (final entry in raw.entries) {
      final key = int.tryParse(entry.key.toString());
      if (key == null) {
        continue;
      }
      breakdown[key] = (entry.value as num?)?.toInt() ?? 0;
    }

    return breakdown;
  }

  PlaceFoodItemModel _mapFoodItem(Map<String, dynamic> json) {
    return PlaceFoodItemModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Món ăn').toString(),
      description: (json['description'] ?? '').toString(),
      price: ((json['price'] as num?) ?? 0).toDouble(),
      imageUrl: (json['image_url'] ?? '').toString(),
      category: json['category']?.toString(),
    );
  }

  PlaceModel _mapRelatedPlace(Map<String, dynamic> json) {
    final image = (json['image'] ?? '').toString();
    return PlaceModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Địa điểm liên quan').toString(),
      imageUrl: image,
      rating: ((json['rating'] as num?) ?? 0).toDouble(),
      district: '',
      city: (json['city'] ?? '').toString(),
    );
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

  String _toTimeAgo(String iso) {
    final date = DateTime.tryParse(iso);
    if (date == null) {
      return 'Vừa xong';
    }

    final diff = DateTime.now().difference(date);
    final days = diff.inDays;
    if (days <= 0) {
      return 'Vừa xong';
    }
    if (days < 30) {
      return '$days ngày trước';
    }
    if (days < 365) {
      return '${(days / 30).floor().clamp(1, 999)} tháng trước';
    }
    return '${(days / 365).floor().clamp(1, 999)} năm trước';
  }

  @override
  Future<PlaceFoodItemsPage> getPlaceFoodItems(
    String id, {
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _client.dio.get(
      '/places/$id/food-items',
      queryParameters: {'page': page, 'limit': limit},
      options: _client.forceRefreshOptions,
    );

    final data = response.data as Map<String, dynamic>;
    final place = (data['place'] as Map<String, dynamic>?) ?? const {};
    final items = _asList(data['items']).map(_mapFoodItem).map((item) => item.toEntity()).toList();
    final pagination = (data['pagination'] as Map<String, dynamic>?) ?? const {};

    return PlaceFoodItemsPage(
      placeId: (place['id'] ?? id).toString(),
      placeName: (place['name'] ?? 'Địa điểm').toString(),
      items: items,
      page: (pagination['page'] as num?)?.toInt() ?? page,
      limit: (pagination['limit'] as num?)?.toInt() ?? limit,
      total: (pagination['total'] as num?)?.toInt() ?? items.length,
      pages: (pagination['pages'] as num?)?.toInt() ?? (items.isEmpty ? 0 : (items.length / limit).ceil()),
    );
  }

  @override
  Future<PlaceReviewsPage> getPlaceReviews(
    String id, {
    String? touristId,
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _client.dio.get(
      '/places/$id/reviews',
      queryParameters: {
        if (touristId != null && touristId.isNotEmpty) 'tourist_id': touristId,
        'page': page,
        'limit': limit,
      },
      options: _client.forceRefreshOptions,
    );

    final data = response.data as Map<String, dynamic>;
    final place = (data['place'] as Map<String, dynamic>?) ?? const {};
    final reviewsInfo = (data['reviews'] as Map<String, dynamic>?) ?? const {};
    final list = _asList(reviewsInfo['list']).map(_mapReview).map((item) => item.toEntity()).toList();
    final breakdown = _mapBreakdown(reviewsInfo['breakdown']);
    final pagination = (reviewsInfo['pagination'] as Map<String, dynamic>?) ?? const {};

    return PlaceReviewsPage(
      placeId: (place['id'] ?? id).toString(),
      placeName: (place['name'] ?? 'Địa điểm').toString(),
      average: ((reviewsInfo['average'] as num?) ?? 0).toDouble(),
      total: (reviewsInfo['total'] as num?)?.toInt() ?? list.length,
      breakdown: breakdown,
      items: list,
      page: (pagination['page'] as num?)?.toInt() ?? page,
      limit: (pagination['limit'] as num?)?.toInt() ?? limit,
      pages: (pagination['pages'] as num?)?.toInt() ?? (list.isEmpty ? 0 : (list.length / limit).ceil()),
    );
  }
}
