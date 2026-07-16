import 'package:json_annotation/json_annotation.dart';

import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_activity_entity.dart';

part 'itinerary_activity_model.g.dart';

@JsonSerializable()
class ItineraryActivityModel {
  final String id;
  @JsonKey(name: 'place_id')
  final String? placeId;
  final String title;
  @JsonKey(name: 'start_time')
  final String startTime;
  @JsonKey(name: 'end_time')
  final String endTime;
  @JsonKey(name: 'location_name')
  final String locationName;
  final String address;
  @JsonKey(name: 'image_url')
  final String imageUrl;
  final double price;
  @JsonKey(name: 'transport_cost')
  final double transportCost;
  final String currency;
  @JsonKey(name: 'transport_info')
  final String? transportInfo;
  final double? transitDistanceKm;
  final int? transitDurationMinutes;
  @JsonKey(name: 'is_free')
  final bool isFree;
  final String? category;
  @JsonKey(name: 'place_type')
  final String? placeType;
  final double? latitude;
  final double? longitude;
  final double? rating;
  @JsonKey(name: 'review_count')
  final int? reviewCount;
  final String? status;
  @JsonKey(name: 'open_hour_compressed')
  final String? openHourCompressed;

  const ItineraryActivityModel({
    required this.id,
    this.placeId,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.locationName,
    required this.address,
    required this.imageUrl,
    this.price = 0,
    this.transportCost = 0,
    this.currency = 'VNĐ',
    this.transportInfo,
    this.transitDistanceKm,
    this.transitDurationMinutes,
    this.isFree = false,
    this.category,
    this.placeType,
    this.latitude,
    this.longitude,
    this.rating,
    this.reviewCount,
    this.status,
    this.openHourCompressed,
  });

  factory ItineraryActivityModel.fromJson(Map<String, dynamic> json) {
    return ItineraryActivityModel(
      id: json['id'] ?? '',
      placeId: json['placeId']?.toString() ?? json['place_id']?.toString(),
      title: json['title'] ?? json['placeName'] ?? '',
      startTime: json['start_time'] ?? json['startTime'] ?? '',
      endTime: json['end_time'] ?? json['endTime'] ?? '',
      locationName:
          json['location_name'] ??
          json['locationName'] ??
          json['placeName'] ??
          '',
      address: json['address'] ?? '',
      imageUrl: json['image_url'] ?? json['imageUrl'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      transportCost:
          (json['transport_cost'] ?? json['transportCost'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'VNĐ',
      transportInfo:
          json['transport_info'] ??
          json['transportInfo'] ??
          (json['transitToNext'] != null
              ? (json['transitToNext']['durationStr'] ?? '')
              : ''),
      transitDistanceKm: json['transitToNext']?['distanceKm'] != null
          ? (json['transitToNext']['distanceKm'] as num).toDouble()
          : null,
      transitDurationMinutes: json['transitToNext']?['durationMinutes'] != null
          ? (json['transitToNext']['durationMinutes'] as num).round()
          : null,
      isFree:
          json['is_free'] ??
          json['isFree'] ??
          (json['priceLabel'] == 'MIỄN PHÍ'),
      category: json['category'],
      placeType: json['placeType']?.toString() ?? json['place_type']?.toString(),
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : (json['lat'] != null ? (json['lat'] as num).toDouble() : null),
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : (json['lng'] != null ? (json['lng'] as num).toDouble() : null),
      rating: json['rating'] != null
          ? (json['rating'] as num).toDouble()
          : null,
      reviewCount: json['review_count'] ?? json['reviewCount'],
      status:
          (json['is_completed'] == true ||
              json['isCompleted'] == true ||
              json['is_visited'] == true ||
              json['is_visted'] == true ||
              json['isVisited'] == true)
          ? 'completed'
          : json['status']?.toString(),
      openHourCompressed: json['open_hour_compressed']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => _$ItineraryActivityModelToJson(this);

  /// Strip seconds from "HH:mm:ss" → "HH:mm". Leaves "HH:mm" unchanged.
  static String _trimSeconds(String time) {
    final parts = time.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return time;
  }

  ItineraryActivityEntity toEntity() {
    ActivityStatus entityStatus = ActivityStatus.chuaDi;
    final normalizedStatus = (status ?? '').toLowerCase();
    if (normalizedStatus == 'dangdi' || normalizedStatus == 'in_progress') {
      entityStatus = ActivityStatus.dangDi;
    }
    if (normalizedStatus == 'dadi' ||
        normalizedStatus == 'visited' ||
        normalizedStatus == 'completed' ||
        normalizedStatus == 'complete' ||
        normalizedStatus == 'done' ||
        normalizedStatus == 'true') {
      entityStatus = ActivityStatus.daDi;
    }
    if (normalizedStatus == 'diqua' || normalizedStatus == 'passed') {
      entityStatus = ActivityStatus.diQua;
    }

    return ItineraryActivityEntity(
      id: id,
      placeId: placeId,
      title: title,
      startTime: _trimSeconds(startTime),
      endTime: _trimSeconds(endTime),
      locationName: locationName,
      address: address,
      imageUrl: imageUrl,
      price: price,
      transportCost: transportCost,
      currency: currency,
      transportInfo: transportInfo,
      transitDistanceKm: transitDistanceKm,
      transitDurationMinutes: transitDurationMinutes,
      isFree: isFree,
      category: category,
      placeType: placeType,
      latitude: latitude,
      longitude: longitude,
      rating: rating,
      reviewCount: reviewCount,
      status: entityStatus,
      openHourCompressed: openHourCompressed,
    );
  }
}
