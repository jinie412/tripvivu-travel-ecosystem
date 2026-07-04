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
  final double estimatedCost;
  final int participantCount;
  final int totalLocations;
  final int visitedLocations;
  final List<String> placeImages;
  final double? rating;

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
  this.estimatedCost = 0,
  this.participantCount = 1,
  this.totalLocations = 0,
  this.visitedLocations = 0,
  this.placeImages = const [],
  this.rating,
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
    estimatedCost: (json['estimated_cost'] as num?)?.toDouble() ?? 0,
    participantCount:
        (json['participantCount'] ?? json['participant_count'] as num?)
            ?.toInt() ??
        1,
    totalLocations: (json['total_locations'] as num?)?.toInt() ?? 0,
    visitedLocations: (json['visited_locations'] as num?)?.toInt() ?? 0,
    placeImages: (json['place_images'] as List<dynamic>?)
            ?.whereType<String>()
            .where((url) => url.isNotEmpty)
            .toList() ??
        [],
    rating: (json['rating'] as num?)?.toDouble(),
  );
}

ItineraryEntity toEntity() {
  return ItineraryEntity(
    id: id,

    /// List API uses `description` as the user-facing trip name.
    /// `destination` is only a fallback for older rows/responses.
    title: description.isNotEmpty ? description : (destination ?? ''),

    /// The list API does not expose a single cover image.
    /// Cards render `placeImages` as the slideshow source instead.
    imageUrl: null,

    startDate: DateTime.tryParse(startDate),
    endDate: DateTime.tryParse(endDate),

    estimatedCost: estimatedCost,
    participantCount: participantCount,

    currency: 'VNĐ',

    totalLocations: totalLocations,
    visitedLocations: visitedLocations,

    /// Backend list field `days` maps to the domain duration.
    durationDays: days,

    /// Backend progress is 0..100; Flutter progress widgets expect 0..1.
    progress: progress / 100,

    status: _mapStatus(status),

    rating: rating,

    placeholderColor: 0xFF42A5F5,
    trackingActive: trackingActive,

    placeImages: placeImages,
  );
}

ItineraryStatus _mapStatus(String? status) {
  switch (status?.toLowerCase()) {
    case 'completed':
      return ItineraryStatus.completed;
    case 'uncompleted':
      return ItineraryStatus.uncompleted;
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
