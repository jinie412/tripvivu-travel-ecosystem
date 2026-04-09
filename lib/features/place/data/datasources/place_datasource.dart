import 'package:dio/dio.dart';
import 'package:travel_advisor_mobile/core/network/dio_client.dart';
import 'package:travel_advisor_mobile/core/utils/auth_utils.dart';
import 'package:travel_advisor_mobile/features/place/data/models/place_detail_model.dart';
import 'package:travel_advisor_mobile/features/place/data/models/place_model.dart';
import 'package:travel_advisor_mobile/features/place/data/models/place_review_model.dart';

abstract class PlaceDataSource {
  Future<PlaceDetailModel> getPlaceDetail(String id);
}

class MockPlaceDataSource implements PlaceDataSource {
  @override
  Future<PlaceDetailModel> getPlaceDetail(String id) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return PlaceDetailModel(
      id: 'nh-001',
      name: 'Nhà hát Thành phố Hồ Chí Minh',
      address: '7 Công Trường Lam Sơn, Quận 1, TP. HCM',
      district: 'Quận 1',
      city: 'TP. HCM',
      rating: 4.5,
      totalReviews: 1248,
      tags: ['Văn hóa - lịch sử', 'Tham quan - chụp ảnh'],
      images: [
        'https://kyhoatourist.com.vn/uploadwb/image/tintuc/nha-hat-lon-2.jpg',
        'https://static.vinwonders.com/production/nha-hat-thanh-pho-1.jpg',
        'https://res.klook.com/images/fl_lossy.progressive,q_65/c_fill,w_1200,h_811/w_74,x_13,y_13,g_south_west,l_Klook_water_br_trans_yhcmh3/activities/i64sjejsothrtuqz43ap/V%C3%A9%C3%80%E1%BB%90Show%E1%BB%9ENh%C3%A0H%C3%A1tTh%C3%A0nhPh%E1%BB%91.jpg',
      ],
      description: 'Nhà Hát Lớn Thành Phố - Thăm quan & chụp ảnh. Sân khấu tại 7 Công Trường Lam Sơn, Quận 1, TP. HCM. Giá bình quân đầu người: 80.000đ - 350.000đ. Đây là công trình kiến trúc đặc sắc của Sài Gòn.',
      openingHours: '10:00',
      closingHours: '23:00',
      phone: '(028) 38 299 919',
      isFavorite: true,
      reviews: [
        PlaceReviewModel(
          id: 'rv-001',
          userName: 'Minh Anh Trần',
          userAvatar: 'https://i.pravatar.cc/150?u=minhanh',
          rating: 5,
          timeAgo: '3 ngày trước',
          reviewText: 'Kiến trúc rất đẹp và cổ kính, buổi tối lên đèn lung linh lắm, cực kỳ hợp để check-in sống ảo.',
          reviewImages: ['https://images.unsplash.com/photo-1583417319070-4a69db38a482?w=400&q=80'],
        ),
        PlaceReviewModel(
          id: 'rv-002',
          userName: 'Thế Hùng',
          userAvatar: 'https://i.pravatar.cc/150?u=thehung',
          rating: 4,
          timeAgo: '1 tuần trước',
          reviewText: 'Địa điểm ngay trung tâm, dễ tìm. Tuy nhiên khá đông đúc vào cuối tuần.',
        ),
      ],
      relatedPlaces: [
        PlaceModel(
          id: 'pl-related-001',
          name: 'Bảo tàng Mỹ thuật',
          imageUrl: 'https://cdn2.fptshop.com.vn/unsafe/1920x0/filters:format(webp):quality(75)/bao_tang_my_thuat_2_5830af02a8.png',
          rating: 4.6,
          district: 'Quận 1',
          city: 'TP. HCM',
        ),
        PlaceModel(
          id: 'pl-related-002',
          name: 'Chùa Ngọc Hoàng',
          imageUrl: 'https://images.unsplash.com/photo-1528127269322-539801943592?w=400&q=80',
          rating: 4.7,
          district: 'Quận 3',
          city: 'TP. HCM',
        ),
      ],
    );
  }
}

class RemotePlaceDataSource implements PlaceDataSource {
  final DioClient _client;

  RemotePlaceDataSource(this._client);

  @override
  Future<PlaceDetailModel> getPlaceDetail(String id) async {
    final touristId = await AuthUtils.getCurrentUserId();

    try {
      final response = await _client.dio.get(
        '/places/$id',
        queryParameters: {
          if (touristId != null && touristId.isNotEmpty) 'tourist_id': touristId,
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
        : (primaryImage.isNotEmpty
            ? <String>[primaryImage]
            : <String>['https://placehold.co/1080x720?text=No+Image']);

    final reviewInfo = (json['reviews'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    final reviewList = (reviewInfo['list'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(_mapReview)
        .toList();

    final related = (json['related_places'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(_mapRelatedPlace)
        .toList();

    return PlaceDetailModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Địa điểm').toString(),
      address: (json['address'] ?? '').toString(),
      district: (json['district'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      rating: ((json['rating'] as num?) ?? 0).toDouble(),
      totalReviews: (reviewInfo['total'] as num?)?.toInt() ?? (json['review_count'] as num?)?.toInt() ?? 0,
      tags: _toStringList(json['tags']),
      images: gallery,
      description: (json['description'] ?? '').toString(),
      openingHours: (json['open_time'] ?? '').toString(),
      closingHours: (json['close_time'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      reviews: reviewList,
      relatedPlaces: related,
      isFavorite: json['is_favorite'] == true,
    );
  }

  PlaceReviewModel _mapReview(Map<String, dynamic> json) {
    final avatarSeed = (json['user_name'] ?? json['id'] ?? 'anonymous').toString();

    return PlaceReviewModel(
      id: (json['id'] ?? '').toString(),
      userName: (json['user_name'] ?? 'Ẩn danh').toString(),
      userAvatar: 'https://i.pravatar.cc/150?u=$avatarSeed',
      rating: ((json['rating'] as num?) ?? 0).toDouble(),
      timeAgo: _toTimeAgo((json['created_at'] ?? '').toString()),
      reviewText: (json['content'] ?? '').toString(),
      reviewImages: const <String>[],
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
    if (diff.inDays >= 1) {
      return '${diff.inDays} ngày trước';
    }
    if (diff.inHours >= 1) {
      return '${diff.inHours} giờ trước';
    }
    if (diff.inMinutes >= 1) {
      return '${diff.inMinutes} phút trước';
    }
    return 'Vừa xong';
  }
}