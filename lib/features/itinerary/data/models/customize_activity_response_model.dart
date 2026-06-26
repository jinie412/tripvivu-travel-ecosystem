import 'package:travel_advisor_mobile/features/itinerary/data/models/itinerary_activity_model.dart';

class CustomizeActivityResponseModel {
  final bool success;
  final String message;
  final int affectedDay;
  final List<ItineraryActivityModel> updatedActivities;
  final List<String>? reorderNotes;

  CustomizeActivityResponseModel({
    required this.success,
    required this.message,
    required this.affectedDay,
    required this.updatedActivities,
    this.reorderNotes,
  });

  factory CustomizeActivityResponseModel.fromJson(Map<String, dynamic> json) {
    return CustomizeActivityResponseModel(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      affectedDay: json['affectedDay'] as int? ?? 1,
      updatedActivities: (json['updatedActivities'] as List<dynamic>?)
              ?.map((e) => ItineraryActivityModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      reorderNotes: (json['reorderNotes'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }
}
