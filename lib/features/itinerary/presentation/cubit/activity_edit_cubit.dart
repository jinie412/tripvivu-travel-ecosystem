import 'activity_edit_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_activity_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/usecases/itinerary_usecases.dart';

class ActivityEditCubit extends Cubit<ActivityEditState> {
  final UpdateActivityUseCase? _updateActivityUseCase;
  String? _itineraryId;

  ActivityEditCubit({UpdateActivityUseCase? updateActivityUseCase})
      : _updateActivityUseCase = updateActivityUseCase,
        super(const ActivityEditLoading());

  void initEdit(ItineraryActivityEntity activity, {String? itineraryId}) {
    _itineraryId = itineraryId;
    emit(ActivityEditInitial(
      activity: activity,
      startTime: activity.startTime,
      endTime: activity.endTime,
      notes: '',
      actualCost: 0.0,
      isEditing: false,
    ));
  }

  void toggleEditMode() {
    if (state is ActivityEditInitial) {
      final s = state as ActivityEditInitial;
      emit(s.copyWith(isEditing: !s.isEditing));
    }
  }

  void updateActualCost(double cost) {
    if (state is ActivityEditInitial) {
      final s = state as ActivityEditInitial;
      emit(s.copyWith(actualCost: cost));
    }
  }

  void updateTime(String start, String end) {
    if (state is ActivityEditInitial) {
      final s = state as ActivityEditInitial;
      emit(s.copyWith(startTime: start, endTime: end));
    }
  }

  void updateNotes(String notes) {
    if (state is ActivityEditInitial) {
      final s = state as ActivityEditInitial;
      emit(s.copyWith(notes: notes));
    }
  }

  Future<void> applyChanges() async {
    final currentState = state;
    if (currentState is! ActivityEditInitial) return;

    emit(const ActivityEditLoading());

    final itineraryId = _itineraryId;
    final useCase = _updateActivityUseCase;

    if (itineraryId != null && useCase != null) {
      try {
        await useCase(
          itineraryId,
          currentState.activity.id,
          arrivalTime: currentState.startTime,
          departureTime: currentState.endTime,
          actualCost: currentState.actualCost,
          userNotes: currentState.notes.isNotEmpty ? currentState.notes : null,
        );
        emit(const ActivityEditSuccess());
      } catch (e) {
        emit(ActivityEditError(e.toString()));
      }
    } else {
      // Demo/mock fallback
      await Future.delayed(const Duration(milliseconds: 800));
      emit(const ActivityEditSuccess());
    }
  }

  void resolveConflict(int option) {
    emit(const ActivityEditSuccess());
  }
}
