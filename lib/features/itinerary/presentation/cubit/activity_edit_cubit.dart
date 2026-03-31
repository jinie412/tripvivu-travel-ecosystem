import 'activity_edit_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_activity_entity.dart';

class ActivityEditCubit extends Cubit<ActivityEditState> {
  ActivityEditCubit() : super(const ActivityEditLoading());

  void initEdit(ItineraryActivityEntity activity) {
    emit(ActivityEditInitial(
      activity: activity,
      startTime: activity.startTime,
      endTime: activity.endTime,
      notes: 'Mua quà lưu niệm cho gia đình ở đây. Nhớ mặc cả giá xuống 30-50%.', // Mock note
      actualCost: 150000.0, // Mock initial actual cost
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

    final endTime = currentState.endTime;
    final actualCost = currentState.actualCost;
    emit(const ActivityEditLoading());
    
    try {
      // Mock network delay
      await Future.delayed(const Duration(milliseconds: 800));
      print('Applying changes with Actual Cost: $actualCost');
      
      // Simulating a potential conflict for demo purposes if end time is 11:00 or later
      if (endTime.startsWith('11:') || endTime.startsWith('12:')) {
         emit(ActivityEditConflictDetected(
          message: 'Lịch trình của bạn đang gặp xung đột về thời gian tại Dinh Độc Lập.',
          activity: currentState.activity,
          notes: currentState.notes,
          startTime: currentState.startTime,
          endTime: currentState.endTime,
        ));
      } else {
        emit(const ActivityEditSuccess());
      }
    } catch (e) {
      emit(ActivityEditError(e.toString()));
    }
  }

  void resolveConflict(int option) {
    // Logic to handle conflict resolution options A, B, C
    emit(const ActivityEditSuccess());
  }
}