import 'package:freezed_annotation/freezed_annotation.dart';

part 'itinerary_activity_entity.freezed.dart';

enum ActivityStatus { chuaDi, dangDi, daDi, diQua }

@freezed
class ItineraryActivityEntity with _$ItineraryActivityEntity {
  const factory ItineraryActivityEntity({
    required String id,
    required String title,
    required String startTime,
    required String endTime,
    required String locationName,
    required String address,
    required String imageUrl,
    @Default(0) double price,
    @Default('VNĐ') String currency,
    String? transportInfo,
    @Default(false) bool isFree,
    String? category, // e.g. "Cà phê", "Tham quan"
    
    // Geographical coordinates
    double? latitude,
    double? longitude,
    
    // Rating and Reviews
    double? rating,
    int? reviewCount,
    
    // Status
    @Default(ActivityStatus.chuaDi) ActivityStatus status,
  }) = _ItineraryActivityEntity;
}