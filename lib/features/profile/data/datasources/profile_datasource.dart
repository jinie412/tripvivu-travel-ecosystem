import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:travel_advisor_mobile/core/network/dio_client.dart';
import 'package:travel_advisor_mobile/core/services/auth_storage.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:travel_advisor_mobile/features/profile/data/models/activity_item_model.dart';
import 'package:travel_advisor_mobile/features/profile/data/models/profile_model.dart';
import 'package:travel_advisor_mobile/features/profile/domain/entities/activity_item_entity.dart';
import 'package:travel_advisor_mobile/core/utils/auth_utils.dart';

abstract class ProfileDataSource {
  Future<ProfileModel> getProfile();
  Future<List<ActivityItemModel>> getRecentActivities();
  Future<String> uploadAvatar(String imagePath);
  Future<ProfileModel> updateProfile({
    String? displayName,
    String? gender,
    List<String>? travelPreferences,
  });
}

class RemoteProfileDataSource implements ProfileDataSource {
  final DioClient dioClient;

  RemoteProfileDataSource(this.dioClient);

  @override
  Future<ProfileModel> getProfile() async {
    final profileResponse = await dioClient.dio.get('/profile/tourist/me');
    return _parseProfileData(profileResponse.data as Map<String, dynamic>);
  }

  @override
  Future<List<ActivityItemModel>> getRecentActivities() async {
    // Chưa có API — trả về danh sách rỗng
    final touristId = await AuthUtils.requireCurrentUserId();
    final response = await dioClient.dio.get(
      '/reviews',
      queryParameters: {'tourist_id': touristId, 'status': 'all'},
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    final reviewed = ((data['reviewed'] as List?) ?? const []).whereType<Map>();
    final pending = ((data['pending'] as List?) ?? const []).whereType<Map>();
    final result = <ActivityItemModel>[];

    void addLatest(
      Iterable<Map> source,
      String kind,
      ActivityType type,
      ActivityStatus itemStatus,
    ) {
      Map? row;
      for (final item in source) {
        if (item['kind'] == kind) {
          row = item;
          break;
        }
      }
      if (row == null) return;
      final itineraryId = (row['itinerary_id'] ?? '').toString();
      final detailId = (row['itinerary_detail_id'] ?? '').toString();
      result.add(
        ActivityItemModel(
          id: '$kind:$itineraryId:$detailId:${row['review_id'] ?? ''}',
          title: (row['title'] ?? 'Đánh giá').toString(),
          type: type,
          status: itemStatus,
          rating: (row['rating'] as num?)?.toDouble(),
          date: DateTime.tryParse((row['reviewed_at'] ?? '').toString()),
        ),
      );
    }

    addLatest(reviewed, 'itinerary', ActivityType.rated, ActivityStatus.none);
    addLatest(reviewed, 'place', ActivityType.rated, ActivityStatus.none);
    addLatest(
      pending,
      'itinerary',
      ActivityType.reviewPending,
      ActivityStatus.pendingReview,
    );
    addLatest(
      pending,
      'place',
      ActivityType.reviewPending,
      ActivityStatus.pendingReview,
    );
    return result;
  }

  @override
  Future<String> uploadAvatar(String imagePath) async {
    final userId = await _getCurrentUserId();

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(imagePath),
      if (userId != null && userId.isNotEmpty) 'userId': userId,
    });

    final response = await dioClient.dio.post(
      '/upload/avatar',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    final data = response.data;

    if (data is Map<String, dynamic> && data['url'] is String) {
      return data['url'] as String;
    }

    throw Exception('Upload avatar failed: invalid response');
  }

  Future<String?> _getCurrentUserId() async {
    final accessToken = await AuthStorage.read('access_token');
    if (accessToken == null || accessToken.isEmpty) return null;

    final parts = accessToken.split('.');
    if (parts.length < 2) return null;

    try {
      final normalized = base64Url.normalize(parts[1]);
      final payload = jsonDecode(utf8.decode(base64Url.decode(normalized)));

      if (payload is Map<String, dynamic>) {
        final userId = payload['userId'] ?? payload['sub'];
        return userId?.toString();
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  // UI label → backend enum (dùng khi gửi lên API)
  static const _interestToEnum = {
    'Biển': 'BEACH',
    'Núi': 'MOUNTAIN',
    'Thành phố': 'CITY',
    'Văn hóa': 'CULTURE',
    'Ẩm thực': 'FOOD',
    'Mua sắm': 'SHOPPING',
    'Nghỉ dưỡng': 'RELAX',
    'Thể thao mạo hiểm': 'SPORTS',
  };

  // Backend enum → UI label (dùng khi nhận từ API)
  static const _enumToInterest = {
    'BEACH': 'Biển',
    'MOUNTAIN': 'Núi',
    'CITY': 'Thành phố',
    'CULTURE': 'Văn hóa',
    'FOOD': 'Ẩm thực',
    'SHOPPING': 'Mua sắm',
    'RELAX': 'Nghỉ dưỡng',
    'SPORTS': 'Thể thao mạo hiểm',
  };

  static String? _mapGenderFromBackend(String? raw) {
    if (raw == null) return null;
    switch (raw.toUpperCase()) {
      case 'MALE':
      case 'NAM':
        return 'Nam';
      case 'FEMALE':
      case 'FEMAIL':
      case 'FEMAILE':
      case 'NỮ':
        return 'Nữ';
      default:
        return raw;
    }
  }

  ProfileModel _parseProfileData(Map<String, dynamic> data) {
    return ProfileModel(
      id: '',
      name: data['displayName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      avatarUrl: data['avatarUrl'] as String? ?? '',
      membershipTier: '',
      reviewPendingCount: 0,
      gender: _mapGenderFromBackend(data['gender'] as String?),
      phoneNumber: data['phoneNumber'] as String?,
      travelPreferences: (data['travelPreferences'] as List<dynamic>?)
          ?.map((e) => _enumToInterest[e.toString()] ?? e.toString())
          .toList(),
    );
  }

  @override
  Future<ProfileModel> updateProfile({
    String? displayName,
    String? gender,
    List<String>? travelPreferences,
  }) async {
    final body = <String, dynamic>{};
    if (displayName != null) body['displayName'] = displayName;
    if (gender != null) {
      switch (gender.toUpperCase()) {
        case 'MALE':
        case 'NAM':
          body['gender'] = 'MALE';
          break;
        case 'FEMALE':
        case 'FEMAIL':
        case 'FEMAILE':
        case 'NỮ':
          body['gender'] = 'FEMALE';
          break;
        default:
          body['gender'] = gender;
      }
    }
    if (travelPreferences != null) {
      body['travelPreferences'] = travelPreferences
          .map((e) => _interestToEnum[e] ?? e)
          .toList();
    }
    final response = await dioClient.dio.patch(
      '/profile/tourist/me',
      data: body,
    );
    return _parseProfileData(response.data as Map<String, dynamic>);
  }
}

class MockProfileDataSource implements ProfileDataSource {
  @override
  Future<ProfileModel> getProfile() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return const ProfileModel(
      id: 'usr-1',
      name: 'Nguyen Van A',
      email: 'nva@example.com',
      avatarUrl:
          'https://images.unsplash.com/photo-1599566150163-29194dcaad36?q=80&w=200',
      membershipTier: 'Thành viên Vàng',
      reviewPendingCount: 2,
      gender: 'Nam',
      phoneNumber: '0973973267',
      travelPreferences: ['Biển', 'Núi', 'Văn hóa', 'Ẩm thực'],
    );
  }

  @override
  Future<ProfileModel> updateProfile({
    String? displayName,
    String? gender,
    List<String>? travelPreferences,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return ProfileModel(
      id: 'usr-1',
      name: displayName ?? 'Nguyễn Văn A',
      email: 'nva@example.com',
      avatarUrl:
          'https://images.unsplash.com/photo-1599566150163-29194dcaad36?q=80&w=200',
      membershipTier: 'Thành viên Vàng',
      reviewPendingCount: 2,
      gender: gender,
      phoneNumber: '0973973267',
      travelPreferences: travelPreferences,
    );
  }

  @override
  Future<String> uploadAvatar(String imagePath) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return 'https://images.unsplash.com/photo-1599566150163-29194dcaad36?q=80&w=200&t=${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<List<ActivityItemModel>> getRecentActivities() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      ActivityItemModel(
        id: 'act-1',
        title: 'Da Lat Palace Hotel',
        type: ActivityType.itinerary,
        rating: 5.0,
        date: DateTime(2023, 10, 20),
      ),
      ActivityItemModel(
        id: 'act-2',
        title: 'Linh Phuoc Pagoda',
        type: ActivityType.rated,
        rating: 4.8,
        date: DateTime(2023, 10, 15),
      ),
      const ActivityItemModel(
        id: 'act-3',
        title: 'Tuyen Lam Lake',
        type: ActivityType.reviewPending,
        status: ActivityStatus.pendingReview,
      ),
      ActivityItemModel(
        id: 'act-4',
        title: 'Banh Mi Saigon',
        type: ActivityType.food,
        code: '#TRV123',
        status: ActivityStatus.preparing,
        restaurantName: 'Com Tam Ba Ghien',
        orderItems: ['Com Tam with Pork', 'Iced Tea'],
      ),
    ];
  }
}

// class RemoteProfileDataSource implements ProfileDataSource {
//   final DioClient _client;

//   RemoteProfileDataSource(this._client);

//   Map<String, dynamic>? _cachedMoreInfo;

//   @override
//   Future<ProfileModel> getProfile() async {
//     final json = await _getMoreInfo();
//     final user = _asMap(json['user']);
//     final placeReviews = _asMap(json['place_reviews']);
//     final touristId = _requireTouristId();

//     final id = (user['id'] ?? touristId).toString();
//     final fullName = (user['full_name'] ?? 'Traveler').toString();
//     final avatarUrl = (user['avatar_url'] ?? '').toString().trim();
//     final membership = (user['membership_label'] ?? 'Member').toString();

//     return ProfileModel(
//       id: id,
//       name: fullName,
//       email: '$id@traveladvisor.app',
//       avatarUrl: avatarUrl.isEmpty ? 'https://i.pravatar.cc/150?u=$id' : avatarUrl,
//       membershipTier: membership,
//       reviewPendingCount: (placeReviews['pending_count'] as num?)?.toInt() ?? 0,
//     );
//   }

//   @override
//   Future<List<ActivityItemModel>> getRecentActivities() async {
//     final json = await _getMoreInfo();
//     final placeReviews = _asMap(json['place_reviews']);
//     final foodOrders = _asMap(json['food_orders']);

//     final reviewed = _asList(placeReviews['reviewed']);
//     final pending = _asList(placeReviews['pending']);
//     final orders = _asList(foodOrders['recent_orders']);

//     final activities = <ActivityItemModel>[];

//     for (final row in reviewed) {
//       final placeId = (row['place_id'] ?? '').toString();
//       final placeName = (row['place_name'] ?? 'Location').toString();
//       final reviewedAt = DateTime.tryParse((row['reviewed_at'] ?? '').toString());
//       activities.add(
//         ActivityItemModel(
//           id: 'review-$placeId-${reviewedAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch}',
//           title: placeName,
//           type: ActivityType.rated,
//           rating: ((row['rating'] as num?) ?? 0).toDouble(),
//           date: reviewedAt,
//         ),
//       );
//     }

//     for (final row in pending) {
//       final placeId = (row['place_id'] ?? '').toString();
//       final placeName = (row['place_name'] ?? 'Location').toString();
//       activities.add(
//         ActivityItemModel(
//           id: 'pending-$placeId',
//           title: placeName,
//           type: ActivityType.reviewPending,
//           status: ActivityStatus.pendingReview,
//         ),
//       );
//     }

//     for (final row in orders) {
//       final rawStatus = (row['status'] ?? '').toString().toLowerCase();
//       final status = rawStatus.contains('deliver') || rawStatus.contains('done')
//           ? ActivityStatus.delivered
//           : ActivityStatus.preparing;
//       final orderItems = (row['items'] is List)
//           ? (row['items'] as List)
//               .whereType<String>()
//               .map((item) => item.trim())
//               .where((item) => item.isNotEmpty)
//               .toList()
//           : null;

//       activities.add(
//         ActivityItemModel(
//           id: (row['id'] ?? row['order_id'] ?? row['order_code'] ?? DateTime.now().millisecondsSinceEpoch)
//               .toString(),
//           title: (row['title'] ?? (orderItems?.isNotEmpty == true ? orderItems!.first : 'Food Order')).toString(),
//           type: ActivityType.food,
//           code: (row['order_code'] ?? row['code'] ?? '').toString(),
//           status: status,
//           restaurantName: (row['restaurant_name'] ?? 'Restaurant').toString(),
//           orderItems: orderItems,
//         ),
//       );
//     }

//     return activities;
//   }

//   Future<Map<String, dynamic>> _getMoreInfo() async {
//     if (_cachedMoreInfo != null) {
//       return _cachedMoreInfo!;
//     }

//     final touristId = _requireTouristId();
//       final response = await _client.dio.get('/more-info?tourist_id=$touristId');

//     _cachedMoreInfo = _asMap(response);
//     return _cachedMoreInfo!;
//   }

//   String _requireTouristId() {
//     final touristId = dotenv.env['EXPLORE_TOURIST_ID'];
//     if (touristId == null || touristId.isEmpty) {
//       throw StateError(
//         'EXPLORE_TOURIST_ID not configured in .env. Required for RemoteProfileDataSource.',
//       );
//     }
//     return touristId;
//   }

//   static Map<String, dynamic> _asMap(dynamic value) {
//     if (value is Map) {
//       return Map<String, dynamic>.from(value);
//     }
//     return {};
//   }

//   static List<dynamic> _asList(dynamic value) {
//     if (value is List) {
//       return value;
//     }
//     return [];
//   }
// }
