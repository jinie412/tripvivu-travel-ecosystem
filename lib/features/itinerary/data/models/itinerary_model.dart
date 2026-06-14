
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_entity.dart';

class ItineraryModel {
  final String id;
  final String description;
  final String? destination;
  final String startDate;
  final String endDate;
  final String? status;
  final int days;
  final int progress;
  final bool trackingActive;

  ItineraryModel({
  required this.id,
  required this.description,
  this.destination,
  required this.startDate,
  required this.endDate,
  this.status,
  required this.days,
  required this.progress,
  this.trackingActive = false,
});

factory ItineraryModel.fromJson(Map<String, dynamic> json) {
  return ItineraryModel(
    id: json['id'] ?? '',
    description: json['description'] ?? '',
    destination: json['destination'],
    startDate: json['start_date'] ?? '',
    endDate: json['end_date'] ?? '',
    status: json['status'],
    days: json['days'] ?? 0,
    progress: json['progress'] ?? 0,
    trackingActive: json['tracking_active'] == true,
  );
}

ItineraryEntity toEntity() {
  return ItineraryEntity(
    id: id,

    /// 🔥 API không có title → dùng destination làm title
    title: description.isNotEmpty ? description : (destination ?? ''),

    /// API chưa có → để null
    imageUrl: null,

    startDate: DateTime.tryParse(startDate),
    endDate: DateTime.tryParse(endDate),

    /// API chưa có cost
    estimatedCost: 0,

    currency: 'VNĐ',

    /// 🔥 FIX: days → durationDays
    durationDays: days,

    /// 🔥 FIX: progress từ 0–100 → 0–1
    progress: progress / 100,

    status: _mapStatus(status),

    /// API chưa có rating
    rating: null,

    placeholderColor: 0xFF42A5F5,
    trackingActive: trackingActive,
  );
}

ItineraryStatus _mapStatus(String? status) {
  switch (status?.toLowerCase()) {
    case 'completed':
      return ItineraryStatus.completed;
    case 'ongoing':
      return ItineraryStatus.ongoing;
    case 'upcoming':
    case 'pending':
      return ItineraryStatus.upcoming;
    case null:
      return ItineraryStatus.draft;
    default:
      return ItineraryStatus.draft;
  }
}}
