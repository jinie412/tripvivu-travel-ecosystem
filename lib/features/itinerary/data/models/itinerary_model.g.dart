// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'itinerary_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ItineraryModel _$ItineraryModelFromJson(Map<String, dynamic> json) =>
    ItineraryModel(
      id: json['id'] as String,
      title: json['title'] as String,
      imageUrl: json['image_url'] as String?,
      startDate: json['start_date'] == null
          ? null
          : DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] == null
          ? null
          : DateTime.parse(json['end_date'] as String),
      estimatedCost: (json['estimated_cost'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'VNĐ',
      durationDays: (json['duration_days'] as num?)?.toInt() ?? 1,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'draft',
      rating: (json['rating'] as num?)?.toDouble(),
      placeholderColor:
          (json['placeholder_color'] as num?)?.toInt() ?? 0xFF90CAF9,
    );

Map<String, dynamic> _$ItineraryModelToJson(ItineraryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'image_url': instance.imageUrl,
      'start_date': instance.startDate?.toIso8601String(),
      'end_date': instance.endDate?.toIso8601String(),
      'estimated_cost': instance.estimatedCost,
      'currency': instance.currency,
      'duration_days': instance.durationDays,
      'progress': instance.progress,
      'status': instance.status,
      'rating': instance.rating,
      'placeholder_color': instance.placeholderColor,
    };
