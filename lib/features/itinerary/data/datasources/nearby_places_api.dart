import 'package:travel_advisor_mobile/core/network/dio_client.dart';
import 'package:travel_advisor_mobile/core/di/injection_container.dart';

class NearbyPlaceModel {
  final String id;
  final String name;
  final String address;
  final String category;
  final double rating;
  final int reviewCount;
  final String imageUrl;
  final double? distanceKm;
  final double? latitude;
  final double? longitude;
  final bool isSameCategory;
  /// JSON giờ mở cửa theo ngày: {"Monday":[["07:00:00","22:00:00"]],...}
  final String? openHourCompressed;

  const NearbyPlaceModel({
    required this.id,
    required this.name,
    required this.address,
    required this.category,
    required this.rating,
    required this.reviewCount,
    required this.imageUrl,
    this.distanceKm,
    this.latitude,
    this.longitude,
    this.isSameCategory = false,
    this.openHourCompressed,
  });

  factory NearbyPlaceModel.fromJson(Map<String, dynamic> json) {
    return NearbyPlaceModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Không xác định',
      address: json['address']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Tham quan',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      imageUrl: json['imageUrl']?.toString() ?? 'https://placehold.co/1080x720?text=No+Image',
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isSameCategory: json['isSameCategory'] as bool? ?? false,
      openHourCompressed: json['openHourCompressed']?.toString(),
    );
  }
}

class NearbyPlacesApi {
  static Future<List<NearbyPlaceModel>> getNearbyPlaces(
    double lat,
    double lng, {
    int limit = 20,
    List<String>? excludeIds,
    String? preferCategory,
    int radius = 10,
  }) async {
    try {
      final client = sl<DioClient>();
      final queryParams = <String, dynamic>{
        'lat': lat,
        'lng': lng,
        'limit': limit,
        'radius': radius,
      };
      if (excludeIds != null && excludeIds.isNotEmpty) {
        queryParams['excludeIds'] = excludeIds.join(',');
      }
      if (preferCategory != null && preferCategory.isNotEmpty) {
        queryParams['preferCategory'] = preferCategory;
      }
      final response = await client.dio.get('/search/nearby', queryParameters: queryParams);

      final data = response.data as List;
      return data.map((json) => NearbyPlaceModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
}
