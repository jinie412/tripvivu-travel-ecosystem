import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:travel_advisor_mobile/core/network/dio_client.dart';
import 'package:travel_advisor_mobile/features/profile/data/models/activity_item_model.dart';
import 'package:travel_advisor_mobile/features/profile/data/models/profile_model.dart';
import 'package:travel_advisor_mobile/features/profile/domain/entities/activity_item_entity.dart';

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
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  RemoteProfileDataSource(this.dioClient);

  @override
  Future<ProfileModel> getProfile() async {
    final response = await dioClient.dio.get('/profile/tourist/me');
    return _parseProfileData(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<ActivityItemModel>> getRecentActivities() async {
    // Chưa có API — trả về danh sách rỗng
    return [];
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
    final accessToken = await _storage.read(key: 'access_token');
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
      name: 'Nguyễn Văn A',
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
        title: 'Đà Lạt Palace Hotel',
        type: ActivityType.itinerary,
        rating: 5.0,
        date: DateTime(2023, 10, 20),
      ),
      ActivityItemModel(
        id: 'act-2',
        title: 'Chùa Linh Phước',
        type: ActivityType.rated,
        rating: 4.8,
        date: DateTime(2023, 10, 15),
      ),
      const ActivityItemModel(
        id: 'act-3',
        title: 'Hồ Tuyền Lâm',
        type: ActivityType.reviewPending,
        status: ActivityStatus.pendingReview,
      ),
      ActivityItemModel(
        id: 'act-4',
        title: 'Bánh mì xíu mại',
        type: ActivityType.food,
        code: '#TRV123',
        status: ActivityStatus.preparing,
        restaurantName: 'Cơm tấm Ba Ghiền',
        orderItems: ['Cơm tấm sườn bì chả', 'Trà đá'],
      ),
      ActivityItemModel(
        id: 'act-5',
        title: 'Lẩu gà lá é',
        type: ActivityType.food,
        code: '#TRV120',
        status: ActivityStatus.delivered,
        restaurantName: 'Lẩu gà lá é Tao Ngộ',
        orderItems: ['Lẩu gà lá é (Lớn)', 'Bún thêm'],
      ),
    ];
  }
}
