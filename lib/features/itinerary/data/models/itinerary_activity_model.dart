import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/itinerary_activity_entity.dart';

part 'itinerary_activity_model.g.dart';

@JsonSerializable()
class ItineraryActivityModel {
  final String id;
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
  final String currency;
  @JsonKey(name: 'transport_info')
  final String? transportInfo;
  @JsonKey(name: 'is_free')
  final bool isFree;
  final String? category;
  final double? latitude;
  final double? longitude;
  final double? rating;
  @JsonKey(name: 'review_count')
  final int? reviewCount;
  final String? status; // chuaDi, dangDi, daDi, diQua

  const ItineraryActivityModel({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.locationName,
    required this.address,
    required this.imageUrl,
    this.price = 0,
    this.currency = 'VNĐ',
    this.transportInfo,
    this.isFree = false,
    this.category,
    this.latitude,
    this.longitude,
    this.rating,
    this.reviewCount,
    this.status,
  });

  factory ItineraryActivityModel.fromJson(Map<String, dynamic> json) =>
      _$ItineraryActivityModelFromJson(json);

  Map<String, dynamic> toJson() => _$ItineraryActivityModelToJson(this);

  ItineraryActivityEntity toEntity() {
    ActivityStatus entityStatus = ActivityStatus.chuaDi;
    if (status == 'dangDi') entityStatus = ActivityStatus.dangDi;
    if (status == 'daDi') entityStatus = ActivityStatus.daDi;
    if (status == 'diQua') entityStatus = ActivityStatus.diQua;

    return ItineraryActivityEntity(
      id: id,
      title: title,
      startTime: startTime,
      endTime: endTime,
      locationName: locationName,
      address: address,
      imageUrl: imageUrl,
      price: price,
      currency: currency,
      transportInfo: transportInfo,
      isFree: isFree,
      category: category,
      latitude: latitude,
      longitude: longitude,
      rating: rating,
      reviewCount: reviewCount,
      status: entityStatus,
    );
  }
}
