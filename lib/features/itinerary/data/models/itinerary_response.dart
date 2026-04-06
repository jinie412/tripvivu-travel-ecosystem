import 'itinerary_model.dart';

class ItineraryResponse {
  final Map<String, dynamic> stats;
  final List<ItineraryModel> itineraries;

  ItineraryResponse({
    required this.stats,
    required this.itineraries,
  });

  factory ItineraryResponse.fromJson(Map<String, dynamic> json) {
    return ItineraryResponse(
      stats: json['stats'] ?? {},
      itineraries: (json['itineraries'] as List)
          .map<ItineraryModel>((e) => ItineraryModel.fromJson(e))
          .toList(),
    );
  }
}