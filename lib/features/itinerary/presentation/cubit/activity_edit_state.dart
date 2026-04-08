import 'package:equatable/equatable.dart';

import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_activity_entity.dart';

abstract class ActivityEditState extends Equatable {
  const ActivityEditState();

  @override
  List<Object?> get props => [];
}

class ActivityEditInitial extends ActivityEditState {
  final ItineraryActivityEntity activity;
  final String notes;
  final String startTime;
  final String endTime;
  final double actualCost;
  final bool isEditing;

  const ActivityEditInitial({
    required this.activity,
    this.notes = '',
    required this.startTime,
    required this.endTime,
    this.actualCost = 0.0,
    this.isEditing = false,
  });

  @override
  List<Object?> get props => [activity, notes, startTime, endTime, actualCost, isEditing];

  ActivityEditInitial copyWith({
    ItineraryActivityEntity? activity,
    String? notes,
    String? startTime,
    String? endTime,
    double? actualCost,
    bool? isEditing,
  }) {
    return ActivityEditInitial(
      activity: activity ?? this.activity,
      notes: notes ?? this.notes,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      actualCost: actualCost ?? this.actualCost,
      isEditing: isEditing ?? this.isEditing,
    );
  }
}

class ActivityEditLoading extends ActivityEditState {
  const ActivityEditLoading();
}

class ActivityEditSuccess extends ActivityEditState {
  const ActivityEditSuccess();
}

class ActivityEditConflictDetected extends ActivityEditState {
  final String message;
  final ItineraryActivityEntity activity;
  final String notes;
  final String startTime;
  final String endTime;
  final double actualCost;
  final bool isEditing;

  const ActivityEditConflictDetected({
    required this.message,
    required this.activity,
    required this.notes,
    required this.startTime,
    required this.endTime,
    this.actualCost = 0.0,
    this.isEditing = true,
  });

  @override
  List<Object?> get props => [message, activity, notes, startTime, endTime, actualCost, isEditing];
}

class ActivityEditError extends ActivityEditState {
  final String message;
  const ActivityEditError(this.message);

  @override
  List<Object?> get props => [message];
}