import 'package:equatable/equatable.dart';
import '../../domain/entities/itinerary_activity_entity.dart';

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

  const ActivityEditInitial({
    required this.activity,
    this.notes = '',
    required this.startTime,
    required this.endTime,
  });

  @override
  List<Object?> get props => [activity, notes, startTime, endTime];
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

  const ActivityEditConflictDetected({
    required this.message,
    required this.activity,
    required this.notes,
    required this.startTime,
    required this.endTime,
  });

  @override
  List<Object?> get props => [message, activity, notes, startTime, endTime];
}

class ActivityEditError extends ActivityEditState {
  final String message;
  const ActivityEditError(this.message);

  @override
  List<Object?> get props => [message];
}
