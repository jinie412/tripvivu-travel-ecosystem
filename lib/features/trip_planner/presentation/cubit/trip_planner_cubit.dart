import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:travel_advisor_mobile/core/utils/auth_utils.dart';
import 'package:travel_advisor_mobile/features/trip_planner/domain/entities/trip_form.dart';
import 'package:travel_advisor_mobile/features/trip_planner/domain/entities/trip_intent_options.dart';
import 'package:travel_advisor_mobile/features/trip_planner/domain/usecases/create_itinerary_usecase.dart';
import 'trip_planner_state.dart';

class TripPlannerCubit extends Cubit<TripPlannerState> {
  final CreateItineraryUseCase _createItinerary;

  TripPlannerCubit({required CreateItineraryUseCase createItinerary})
    : _createItinerary = createItinerary,
      super(
        const TripPlannerState.loaded(
          tripForm: TripForm(transportation: Transportation.car),
        ),
      );

  // ── Bước 1: Địa điểm ────────────────────────────────────────────────────────

  void updateDeparture(String name, String id) {
    state.maybeWhen(
      loaded: (form) => emit(
        TripPlannerState.loaded(
          tripForm: form.copyWith(
            departureLocation: name,
            departureLocationId: id,
          ),
        ),
      ),
      orElse: () {},
    );
  }

  void updateDestination(String name, String id) {
    state.maybeWhen(
      loaded: (form) => emit(
        TripPlannerState.loaded(
          tripForm: form.copyWith(
            destinationLocation: name,
            destinationLocationId: id,
          ),
        ),
      ),
      orElse: () {},
    );
  }

  void swapLocations() {
    state.maybeWhen(
      loaded: (form) => emit(
        TripPlannerState.loaded(
          tripForm: form.copyWith(
            departureLocation: form.destinationLocation,
            departureLocationId: form.destinationLocationId,
            destinationLocation: form.departureLocation,
            destinationLocationId: form.departureLocationId,
          ),
        ),
      ),
      orElse: () {},
    );
  }

  void updateTripType(TripType type) {
    state.maybeWhen(
      loaded: (form) => emit(
        TripPlannerState.loaded(tripForm: form.copyWith(tripType: type)),
      ),
      orElse: () {},
    );
  }

  void updateTransportation(Transportation transport) {
    state.maybeWhen(
      loaded: (form) => emit(
        TripPlannerState.loaded(
          tripForm: form.copyWith(transportation: transport),
        ),
      ),
      orElse: () {},
    );
  }

  // ── Bước 2: Thời gian & Chủ đề ──────────────────────────────────────────────

  void updateStartDate(DateTime date) {
    state.maybeWhen(
      loaded: (form) {
        // Đảm bảo endDate không trước startDate
        final end = form.endDate != null && form.endDate!.isBefore(date)
            ? date
            : form.endDate;
        emit(
          TripPlannerState.loaded(
            tripForm: form.copyWith(startDate: date, endDate: end),
          ),
        );
      },
      orElse: () {},
    );
  }

  void updateEndDate(DateTime date) {
    state.maybeWhen(
      loaded: (form) =>
          emit(TripPlannerState.loaded(tripForm: form.copyWith(endDate: date))),
      orElse: () {},
    );
  }

  void updateStartTime(String time) {
    state.maybeWhen(
      loaded: (form) => emit(
        TripPlannerState.loaded(tripForm: form.copyWith(startTime: time)),
      ),
      orElse: () {},
    );
  }

  void updateEndTime(String time) {
    state.maybeWhen(
      loaded: (form) =>
          emit(TripPlannerState.loaded(tripForm: form.copyWith(endTime: time))),
      orElse: () {},
    );
  }

  void updateTripIntent(String intent) {
    state.maybeWhen(
      loaded: (form) => emit(
        TripPlannerState.loaded(tripForm: form.copyWith(tripIntent: intent)),
      ),
      orElse: () {},
    );
  }

  // ── Bước 2: Thành viên ──────────────────────────────────────────────────────

  void increaseAdults() {
    state.maybeWhen(
      loaded: (form) => emit(
        TripPlannerState.loaded(
          tripForm: form.copyWith(adultCount: form.adultCount + 1),
        ),
      ),
      orElse: () {},
    );
  }

  void decreaseAdults() {
    state.maybeWhen(
      loaded: (form) {
        if (form.adultCount > 1) {
          emit(
            TripPlannerState.loaded(
              tripForm: form.copyWith(adultCount: form.adultCount - 1),
            ),
          );
        }
      },
      orElse: () {},
    );
  }

  void increaseChildren() {
    state.maybeWhen(
      loaded: (form) => emit(
        TripPlannerState.loaded(
          tripForm: form.copyWith(childCount: form.childCount + 1),
        ),
      ),
      orElse: () {},
    );
  }

  void decreaseChildren() {
    state.maybeWhen(
      loaded: (form) {
        if (form.childCount > 0) {
          emit(
            TripPlannerState.loaded(
              tripForm: form.copyWith(childCount: form.childCount - 1),
            ),
          );
        }
      },
      orElse: () {},
    );
  }

  // ── Bước 3: Ngân sách & Ẩm thực ─────────────────────────────────────────────

  void updateBudget(double amount) {
    state.maybeWhen(
      loaded: (form) => emit(
        TripPlannerState.loaded(tripForm: form.copyWith(budget: amount)),
      ),
      orElse: () {},
    );
  }

  void toggleFoodPreference(String preference) {
    state.maybeWhen(
      loaded: (form) {
        final list = List<String>.from(form.foodPreferences);
        if (list.contains(preference)) {
          list.remove(preference);
        } else {
          list.add(preference);
        }
        emit(
          TripPlannerState.loaded(
            tripForm: form.copyWith(foodPreferences: list),
          ),
        );
      },
      orElse: () {},
    );
  }

  // ── Navigation ───────────────────────────────────────────────────────────────

  void goNextStep() {
    state.maybeWhen(
      loaded: (form) {
        if (form.currentStep < 3) {
          emit(
            TripPlannerState.loaded(
              tripForm: form.copyWith(currentStep: form.currentStep + 1),
            ),
          );
        }
      },
      orElse: () {},
    );
  }

  void goPrevStep() {
    state.maybeWhen(
      loaded: (form) {
        if (form.currentStep > 1) {
          emit(
            TripPlannerState.loaded(
              tripForm: form.copyWith(currentStep: form.currentStep - 1),
            ),
          );
        }
      },
      orElse: () {},
    );
  }

  // ── Submit ───────────────────────────────────────────────────────────────────

  Future<void> submitTripPlan() async {
    final form = state.whenOrNull(loaded: (f) => f);
    if (form == null) return;

    // Validation
    if (form.departureLocationId == null || form.departureLocationId!.isEmpty) {
      emit(TripPlannerState.error('Vui lòng chọn điểm khởi hành'));
      emit(TripPlannerState.loaded(tripForm: form));
      return;
    }
    if (form.destinationLocationId == null ||
        form.destinationLocationId!.isEmpty) {
      emit(TripPlannerState.error('Vui lòng chọn điểm đến'));
      emit(TripPlannerState.loaded(tripForm: form));
      return;
    }
    if (form.departureLocationId == form.destinationLocationId) {
      emit(
        TripPlannerState.error(
          'Điểm khởi hành và điểm đến không được trùng nhau',
        ),
      );
      emit(TripPlannerState.loaded(tripForm: form));
      return;
    }
    if (form.startDate == null) {
      emit(TripPlannerState.error('Vui lòng chọn ngày bắt đầu'));
      emit(TripPlannerState.loaded(tripForm: form));
      return;
    }
    if (form.endDate == null) {
      emit(TripPlannerState.error('Vui lòng chọn ngày kết thúc'));
      emit(TripPlannerState.loaded(tripForm: form));
      return;
    }
    if (form.endDate!.isBefore(form.startDate!)) {
      emit(
        TripPlannerState.error('Ngày kết thúc không được trước ngày bắt đầu'),
      );
      emit(TripPlannerState.loaded(tripForm: form));
      return;
    }
    final dailyStartTime = form.startTime ?? '07:00';
    final dailyEndTime = form.endTime ?? '22:00';
    if (!_isValidTimeRange(dailyStartTime, dailyEndTime)) {
      emit(TripPlannerState.error('Giờ kết thúc phải sau giờ bắt đầu'));
      emit(TripPlannerState.loaded(tripForm: form));
      return;
    }
    if (form.tripIntent != null && !kTripIntents.contains(form.tripIntent)) {
      emit(TripPlannerState.error('Mục đích chuyến đi không hợp lệ'));
      emit(TripPlannerState.loaded(tripForm: form));
      return;
    }
    if (form.adultCount < 1) {
      emit(TripPlannerState.error('Chuyến đi phải có ít nhất 1 người lớn'));
      emit(TripPlannerState.loaded(tripForm: form));
      return;
    }

    emit(const TripPlannerState.generating());
    try {
      final userId = await AuthUtils.requireCurrentUserId();

      final id = await _createItinerary(
        CreateItineraryParams(
          userId: userId,
          tripType: _tripTypeToApi(form.tripType),
          departureLocationId: form.departureLocationId!,
          destinationLocationId: form.destinationLocationId!,
          transportMode: _transportToApi(form.transportation),
          startDate: _formatDate(form.startDate),
          endDate: _formatDate(form.endDate),
          dailyStartTime: dailyStartTime,
          dailyEndTime: dailyEndTime,
          tripIntent: form.tripIntent ?? kTripIntents.first,
          adultCount: form.adultCount,
          childCount: form.childCount,
          budget: form.budget,
          foodPreferences: form.foodPreferences,
        ),
      );

      emit(TripPlannerState.success(itineraryId: id));
    } catch (e) {
      emit(TripPlannerState.error(e.toString()));
      emit(TripPlannerState.loaded(tripForm: form));
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _formatDate(DateTime? date) {
    if (date == null) {
      throw StateError('Trip date must be selected before submit');
    }
    return DateFormat('yyyy-MM-dd').format(date);
  }

  bool _isValidTimeRange(String start, String end) {
    final startMinutes = _timeToMinutes(start);
    final endMinutes = _timeToMinutes(end);
    return startMinutes != null &&
        endMinutes != null &&
        startMinutes < endMinutes;
  }

  int? _timeToMinutes(String time) {
    final match = RegExp(r'^([01]?\d|2[0-3]):([0-5]\d)$').firstMatch(time);
    if (match == null) return null;
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    return hour * 60 + minute;
  }

  String _tripTypeToApi(TripType type) {
    switch (type) {
      case TripType.roundTrip:
        return 'ROUND_TRIP';
      case TripType.oneWay:
        return 'ONE_WAY';
    }
  }

  String _transportToApi(Transportation t) {
    switch (t) {
      case Transportation.car:
        return 'CAR';
      case Transportation.motorbike:
        return 'MOTORBIKE';
    }
  }
}
