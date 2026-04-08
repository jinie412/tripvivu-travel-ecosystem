import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:travel_advisor_mobile/core/network/dio_client.dart';
import 'package:travel_advisor_mobile/features/profile/data/models/activity_item_model.dart';
import 'package:travel_advisor_mobile/features/profile/data/models/profile_model.dart';
import 'package:travel_advisor_mobile/features/profile/domain/entities/activity_item_entity.dart';

abstract class ProfileDataSource {
  Future<ProfileModel> getProfile();
  Future<List<ActivityItemModel>> getRecentActivities();
}

class MockProfileDataSource implements ProfileDataSource {
  @override
  Future<ProfileModel> getProfile() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return const ProfileModel(
      id: 'usr-1',
      name: 'Nguyen Van A',
      email: 'nva@example.com',
      avatarUrl: 'https://images.unsplash.com/photo-1599566150163-29194dcaad36?q=80&w=200',
      membershipTier: 'Gold Member',
      reviewPendingCount: 2,
    );
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

class RemoteProfileDataSource implements ProfileDataSource {
  final DioClient _client;

  RemoteProfileDataSource(this._client);

  Map<String, dynamic>? _cachedMoreInfo;

  @override
  Future<ProfileModel> getProfile() async {
    final json = await _getMoreInfo();
    final user = _asMap(json['user']);
    final placeReviews = _asMap(json['place_reviews']);
    final touristId = _requireTouristId();

    final id = (user['id'] ?? touristId).toString();
    final fullName = (user['full_name'] ?? 'Traveler').toString();
    final avatarUrl = (user['avatar_url'] ?? '').toString().trim();
    final membership = (user['membership_label'] ?? 'Member').toString();

    return ProfileModel(
      id: id,
      name: fullName,
      email: '$id@traveladvisor.app',
      avatarUrl: avatarUrl.isEmpty ? 'https://i.pravatar.cc/150?u=$id' : avatarUrl,
      membershipTier: membership,
      reviewPendingCount: (placeReviews['pending_count'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<List<ActivityItemModel>> getRecentActivities() async {
    final json = await _getMoreInfo();
    final placeReviews = _asMap(json['place_reviews']);
    final foodOrders = _asMap(json['food_orders']);

    final reviewed = _asList(placeReviews['reviewed']);
    final pending = _asList(placeReviews['pending']);
    final orders = _asList(foodOrders['recent_orders']);

    final activities = <ActivityItemModel>[];

    for (final row in reviewed) {
      final placeId = (row['place_id'] ?? '').toString();
      final placeName = (row['place_name'] ?? 'Location').toString();
      final reviewedAt = DateTime.tryParse((row['reviewed_at'] ?? '').toString());
      activities.add(
        ActivityItemModel(
          id: 'review-$placeId-${reviewedAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch}',
          title: placeName,
          type: ActivityType.rated,
          rating: ((row['rating'] as num?) ?? 0).toDouble(),
          date: reviewedAt,
        ),
      );
    }

    for (final row in pending) {
      final placeId = (row['place_id'] ?? '').toString();
      final placeName = (row['place_name'] ?? 'Location').toString();
      activities.add(
        ActivityItemModel(
          id: 'pending-$placeId',
          title: placeName,
          type: ActivityType.reviewPending,
          status: ActivityStatus.pendingReview,
        ),
      );
    }

    for (final row in orders) {
      final rawStatus = (row['status'] ?? '').toString().toLowerCase();
      final status = rawStatus.contains('deliver') || rawStatus.contains('done')
          ? ActivityStatus.delivered
          : ActivityStatus.preparing;
      final orderItems = (row['items'] is List)
          ? (row['items'] as List)
              .whereType<String>()
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .toList()
          : null;

      activities.add(
        ActivityItemModel(
          id: (row['id'] ?? row['order_id'] ?? row['order_code'] ?? DateTime.now().millisecondsSinceEpoch)
              .toString(),
          title: (row['title'] ?? (orderItems?.isNotEmpty == true ? orderItems!.first : 'Food Order')).toString(),
          type: ActivityType.food,
          code: (row['order_code'] ?? row['code'] ?? '').toString(),
          status: status,
          restaurantName: (row['restaurant_name'] ?? 'Restaurant').toString(),
          orderItems: orderItems,
        ),
      );
    }

    return activities;
  }

  Future<Map<String, dynamic>> _getMoreInfo() async {
    if (_cachedMoreInfo != null) {
      return _cachedMoreInfo!;
    }

    final touristId = _requireTouristId();
      final response = await _client.dio.get('/more-info?tourist_id=$touristId');

    _cachedMoreInfo = _asMap(response);
    return _cachedMoreInfo!;
  }

  String _requireTouristId() {
    final touristId = dotenv.env['EXPLORE_TOURIST_ID'];
    if (touristId == null || touristId.isEmpty) {
      throw StateError(
        'EXPLORE_TOURIST_ID not configured in .env. Required for RemoteProfileDataSource.',
      );
    }
    return touristId;
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return {};
  }

  static List<dynamic> _asList(dynamic value) {
    if (value is List) {
      return value;
    }
    return [];
  }
}
