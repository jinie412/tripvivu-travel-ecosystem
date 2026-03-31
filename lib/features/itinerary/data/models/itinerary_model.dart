import 'package:json_annotation/json_annotation.dart';

import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_entity.dart';

part 'itinerary_model.g.dart';

/// DTO — chuyển đổi giữa JSON (API) và [ItineraryEntity] (Domain).
///
/// Trường `status` được map từ String sang enum [ItineraryStatus].
@JsonSerializable()
class ItineraryModel {
  final String id;
  final String title;

  @JsonKey(name: 'image_url')
  final String? imageUrl;

  @JsonKey(name: 'start_date')
  final DateTime? startDate;

  @JsonKey(name: 'end_date')
  final DateTime? endDate;

  @JsonKey(name: 'estimated_cost')
  final double estimatedCost;

  final String currency;

  @JsonKey(name: 'duration_days')
  final int durationDays;

  final double progress;
  final String status;
  final double? rating;

  @JsonKey(name: 'placeholder_color')
  final int placeholderColor;

  const ItineraryModel({
    required this.id,
    required this.title,
    this.imageUrl,
    this.startDate,
    this.endDate,
    this.estimatedCost = 0,
    this.currency = 'VNĐ',
    this.durationDays = 1,
    this.progress = 0.0,
    this.status = 'draft',
    this.rating,
    this.placeholderColor = 0xFF90CAF9,
  });

  factory ItineraryModel.fromJson(Map<String, dynamic> json) =>
      _$ItineraryModelFromJson(json);

  Map<String, dynamic> toJson() => _$ItineraryModelToJson(this);

  /// Chuyển đổi DTO → Entity để sử dụng trong Domain/Presentation.
  ItineraryEntity toEntity() {
    return ItineraryEntity(
      id: id,
      title: title,
      imageUrl: imageUrl,
      startDate: startDate,
      endDate: endDate,
      estimatedCost: estimatedCost,
      currency: currency,
      durationDays: durationDays,
      progress: progress,
      status: _parseStatus(status),
      rating: rating,
      placeholderColor: placeholderColor,
    );
  }

  /// Parse string → enum. Mặc định draft nếu giá trị không hợp lệ.
  static ItineraryStatus _parseStatus(String raw) {
    switch (raw) {
      case 'upcoming':
        return ItineraryStatus.upcoming;
      case 'completed':
        return ItineraryStatus.completed;
      case 'draft':
      default:
        return ItineraryStatus.draft;
    }
  }
}