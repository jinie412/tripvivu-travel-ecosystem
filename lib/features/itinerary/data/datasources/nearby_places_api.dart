import 'package:travel_advisor_mobile/core/network/dio_client.dart';
import 'package:travel_advisor_mobile/core/di/injection_container.dart';

class NearbyPlaceModel {
  final String id;
  final String name;
  final String address;
  final String category;
  final double rating;
  final int reviewCount;
  final double estimatedCost;
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
    this.estimatedCost = 0,
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
      estimatedCost: json['estimatedCost'] is num
          ? (json['estimatedCost'] as num).toDouble()
          : json['estimated_cost'] is num
          ? (json['estimated_cost'] as num).toDouble()
          : 0.0,
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
  /// Empty for itineraries created before the candidate table existed —
  /// caller should fall back to [getNearbyPlaces].
  static Future<List<NearbyPlaceModel>> getCandidateSuggestions(
    String itineraryId, {
    int limit = 10,
  }) async {
    try {
      final client = sl<DioClient>();
      final response = await client.dio.get(
        '/itinerary/$itineraryId/place-suggestions',
        queryParameters: {'limit': limit},
      );

      final data = response.data as List;
      return data.map((json) => NearbyPlaceModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<NearbyPlaceModel>> getReplaceSuggestions(
    String itineraryId,
    String activityId,
  ) async {
    try {
      final client = sl<DioClient>();
      final response = await client.dio.get(
        '/itinerary/$itineraryId/activities/$activityId/suggestions',
      );

      final data = response.data?['suggestions'] as List? ?? [];
      return data.map((json) => NearbyPlaceModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<NearbyPlaceModel>> getNearbyPlaces(
    double lat,
    double lng, {
    int limit = 20,
    List<String>? excludeIds,
    String? preferCategory,
    int radius = 10,
    String? q,
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
      if (q != null && q.isNotEmpty) {
        queryParams['q'] = q;
      }
      final response = await client.dio.get('/search/nearby', queryParameters: queryParams);

      final data = response.data as List;
      return data.map((json) => NearbyPlaceModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
}
