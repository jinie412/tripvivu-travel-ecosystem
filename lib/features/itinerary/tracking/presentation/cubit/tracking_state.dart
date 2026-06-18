import 'package:equatable/equatable.dart';

import '../../data/models/tracking_models.dart';

enum TrackingPhase { idle, starting, active, error }

class TrackingState extends Equatable {
  final TrackingPhase phase;
  final String? itineraryId;
  final DateTime? date;
  final List<TrackingPlaceStatus> places;
  final int registeredCount;
  final String? checkingInDetailId; // điểm đang check-in thủ công
  final String? message; // lỗi hoặc thông báo ngắn
  // Quán ăn gần vị trí hiện tại (trong kBán kính cấu hình)
  final String? nearbyRestaurantDetailId;
  final String? nearbyRestaurantName;

  const TrackingState({
    this.phase = TrackingPhase.idle,
    this.itineraryId,
    this.date,
    this.places = const [],
    this.registeredCount = 0,
    this.checkingInDetailId,
    this.message,
    this.nearbyRestaurantDetailId,
    this.nearbyRestaurantName,
  });

  bool get isActive => phase == TrackingPhase.active;
  bool get isStarting => phase == TrackingPhase.starting;

  int get visitedCount =>
      places.where((p) => p.status == VisitStatus.visited).length;
  int get totalCount => places.length;

  /// Tra trạng thái theo itineraryDetailId.
  TrackingPlaceStatus? byDetailId(String id) {
    for (final p in places) {
      if (p.itineraryDetailId == id) return p;
    }
    return null;
  }

  TrackingState copyWith({
    TrackingPhase? phase,
    String? itineraryId,
    DateTime? date,
    List<TrackingPlaceStatus>? places,
    int? registeredCount,
    String? checkingInDetailId,
    bool clearCheckingIn = false,
    String? message,
    bool clearMessage = false,
    String? nearbyRestaurantDetailId,
    String? nearbyRestaurantName,
    bool clearNearbyRestaurant = false,
  }) {
    return TrackingState(
      phase: phase ?? this.phase,
      itineraryId: itineraryId ?? this.itineraryId,
      date: date ?? this.date,
      places: places ?? this.places,
      registeredCount: registeredCount ?? this.registeredCount,
      checkingInDetailId:
          clearCheckingIn ? null : (checkingInDetailId ?? this.checkingInDetailId),
      message: clearMessage ? null : (message ?? this.message),
      nearbyRestaurantDetailId: clearNearbyRestaurant
          ? null
          : (nearbyRestaurantDetailId ?? this.nearbyRestaurantDetailId),
      nearbyRestaurantName: clearNearbyRestaurant
          ? null
          : (nearbyRestaurantName ?? this.nearbyRestaurantName),
    );
  }

  @override
  List<Object?> get props => [
        phase,
        itineraryId,
        date,
        places,
        registeredCount,
        checkingInDetailId,
        message,
        nearbyRestaurantDetailId,
        nearbyRestaurantName,
      ];
}
