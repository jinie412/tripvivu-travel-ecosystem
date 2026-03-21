import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/itinerary_activity_entity.dart';
import 'activity_edit_state.dart';

class ActivityEditCubit extends Cubit<ActivityEditState> {
  ActivityEditCubit() : super(const ActivityEditLoading());

  void initEdit(ItineraryActivityEntity activity) {
    emit(ActivityEditInitial(
      activity: activity,
      startTime: activity.startTime,
      endTime: activity.endTime,
      notes: 'Mua quà lưu niệm cho gia đình ở đây. Nhớ mặc cả giá xuống 30-50%.', // Mock note
    ));
  }

  void updateTime(String start, String end) {
    if (state is ActivityEditInitial) {
      final s = state as ActivityEditInitial;
      emit(ActivityEditInitial(
        activity: s.activity,
        notes: s.notes,
        startTime: start,
        endTime: end,
      ));
    }
  }

  void updateNotes(String notes) {
    if (state is ActivityEditInitial) {
      final s = state as ActivityEditInitial;
      emit(ActivityEditInitial(
        activity: s.activity,
        notes: notes,
        startTime: s.startTime,
        endTime: s.endTime,
      ));
    }
  }

  Future<void> applyChanges() async {
    final currentState = state;
    if (currentState is! ActivityEditInitial) return;

    final endTime = currentState.endTime;
    emit(const ActivityEditLoading());
    
    try {
      // Mock network delay
      await Future.delayed(const Duration(milliseconds: 800));
      
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
