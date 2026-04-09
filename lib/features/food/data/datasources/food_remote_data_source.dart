import 'package:travel_advisor_mobile/core/network/dio_client.dart';
import 'package:travel_advisor_mobile/core/utils/auth_utils.dart';
import 'package:travel_advisor_mobile/features/food/domain/entities/food_item_entity.dart';

class OrderEligiblePlace {
  final int order;
  final String itineraryDetailId;
  final String placeId;
  final String placeName;
  final String? arrivalTime;
  final String? visitDate;
  final List<String> categories;

  const OrderEligiblePlace({
    required this.order,
    required this.itineraryDetailId,
    required this.placeId,
    required this.placeName,
    required this.arrivalTime,
    required this.visitDate,
    required this.categories,
  });
}

class OrderPopupData {
  final String placeId;
  final String placeName;
  final String title;
  final String message;
  final int estimatedWaitMinutes;
  final double rating;
  final int reviewCount;

  const OrderPopupData({
    required this.placeId,
    required this.placeName,
    required this.title,
    required this.message,
    required this.estimatedWaitMinutes,
    required this.rating,
    required this.reviewCount,
  });
}

class FoodMenuData {
  final String placeId;
  final String placeName;
  final List<FoodItemEntity> items;

  const FoodMenuData({
    required this.placeId,
    required this.placeName,
    required this.items,
  });
}

class CreateOrderItemInput {
  final String foodItemId;
  final int quantity;

  const CreateOrderItemInput({
    required this.foodItemId,
    required this.quantity,
  });
}

class CreateOrderResult {
  final String orderId;
  final double totalAmount;

  const CreateOrderResult({
    required this.orderId,
    required this.totalAmount,
  });
}

class FoodRemoteDataSource {
  final DioClient _client;

  FoodRemoteDataSource(this._client);



  List<Map<String, dynamic>> _asList(dynamic raw) {
    if (raw is! List) {
      return const [];
    }
    return raw.whereType<Map<String, dynamic>>().toList();
  }

  List<String> _asStringList(dynamic raw) {
    if (raw is! List) {
      return const [];
    }

    return raw
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Future<List<OrderEligiblePlace>> getItineraryOrderPlaces({
    required String itineraryId,
  }) async {
    final touristId = await AuthUtils.requireCurrentUserId();
    final response = await _client.dio.get(
      '/itineraries/$itineraryId/order/places',
      queryParameters: {'tourist_id': touristId},
    );

    final data = response.data as Map<String, dynamic>;
    final places = _asList(data['places']);

    return places
        .map(
          (item) => OrderEligiblePlace(
            order: (item['order'] as num?)?.toInt() ?? 0,
            itineraryDetailId: (item['itinerary_detail_id'] ?? '').toString(),
            placeId: (item['place_id'] ?? '').toString(),
            placeName: (item['place_name'] ?? 'Nhà hàng').toString(),
            arrivalTime: item['arrival_time']?.toString(),
            visitDate: item['visit_date']?.toString(),
            categories: _asStringList(item['categories']),
          ),
        )
        .where((item) => item.placeId.isNotEmpty)
        .toList();
  }

  Future<OrderPopupData> getOrderPopup(String placeId) async {
    final response = await _client.dio.get('/places/$placeId/order/popup');
    final data = response.data as Map<String, dynamic>;
    final place = (data['place'] as Map<String, dynamic>?) ?? const {};
    final suggestion =
        (data['suggestion'] as Map<String, dynamic>?) ?? const {};
    final meta = (data['meta'] as Map<String, dynamic>?) ?? const {};

    return OrderPopupData(
      placeId: (place['id'] ?? placeId).toString(),
      placeName: (place['name'] ?? 'Nhà hàng').toString(),
      title: ('Gợi ý cho bạn').toString(),
      message: (suggestion['message'] ??
              'Bạn có muốn đặt trước món ăn để không phải chờ đợi khi đến nơi?')
          .toString(),
      estimatedWaitMinutes: (meta['estimated_wait_minutes'] as num?)?.toInt() ??
          20,
      rating: ((meta['rating'] as num?) ?? 0).toDouble(),
      reviewCount: (meta['review_count'] as num?)?.toInt() ?? 0,
    );
  }

  Future<FoodMenuData> getFoodItems({
    required String placeId,
    String category = 'all',
    String? search,
    int page = 1,
    int limit = 100,
  }) async {
    final response = await _client.dio.get(
      '/places/$placeId/order/items',
      queryParameters: {
        'category': category,
        if (search != null && search.trim().isNotEmpty) 'search': search,
        'page': page,
        'limit': limit,
      },
    );

    final data = response.data as Map<String, dynamic>;
    final place = (data['place'] as Map<String, dynamic>?) ?? const {};
    final items = _asList(data['items'])
        .map(
          (item) => FoodItemEntity(
            id: (item['id'] ?? '').toString(),
            title: (item['name'] ?? '').toString(),
            description: (item['description'] ?? '').toString(),
            price: ((item['price'] as num?) ?? 0).toDouble(),
            imageUrl: (item['image_url'] ?? '').toString(),
            category: (item['category'] ?? 'main').toString(),
          ),
        )
        .where((item) => item.id.isNotEmpty)
        .toList();

    return FoodMenuData(
      placeId: placeId,
      placeName: (place['name'] ?? 'Nhà hàng').toString(),
      items: items,
    );
  }

  Future<CreateOrderResult> createOrder({
    required String placeId,
    String? itineraryDetailId,
    String? notes,
    required List<CreateOrderItemInput> items,
  }) async {
    if (items.isEmpty) {
      throw Exception('Không có món nào để đặt');
    }

    final touristId = await AuthUtils.requireCurrentUserId();
    final response = await _client.dio.post(
      '/places/$placeId/order',
      data: {
        'tourist_id': touristId,
        if (itineraryDetailId != null && itineraryDetailId.trim().isNotEmpty)
          'itinerary_detail_id': itineraryDetailId,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes,
        'items': items
            .map(
              (item) => {
                'food_item_id': item.foodItemId,
                'quantity': item.quantity,
              },
            )
            .toList(),
      },
    );

    final data = response.data as Map<String, dynamic>;
    return CreateOrderResult(
      orderId: (data['order_id'] ?? '').toString(),
      totalAmount: ((data['total_amount'] as num?) ?? 0).toDouble(),
    );
  }
}
