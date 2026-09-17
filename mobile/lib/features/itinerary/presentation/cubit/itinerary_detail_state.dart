import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_detail_entity.dart';

abstract class ItineraryDetailState {}

class ItineraryDetailInitial extends ItineraryDetailState {}

class ItineraryDetailLoading extends ItineraryDetailState {}

class ItineraryDetailLoaded extends ItineraryDetailState {
  final ItineraryDetailEntity itinerary;
  final int selectedDay; // 1-based index

  ItineraryDetailLoaded({
    required this.itinerary,
    this.selectedDay = 1,
  });

  ItineraryDetailLoaded copyWith({
    ItineraryDetailEntity? itinerary,
    int? selectedDay,
  }) {
    return ItineraryDetailLoaded(
      itinerary: itinerary ?? this.itinerary,
      selectedDay: selectedDay ?? this.selectedDay,
    );
  }
}

class ItineraryDetailError extends ItineraryDetailState {
  final String message;
  ItineraryDetailError(this.message);
}