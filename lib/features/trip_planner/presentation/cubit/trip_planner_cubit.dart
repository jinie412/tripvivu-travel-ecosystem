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

  // â”€â”€ BÆ°á»›c 1: Äá»‹a Ä‘iá»ƒm â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

  // â”€â”€ BÆ°á»›c 2: Thá»i gian & Chá»§ Ä‘á» â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void updateStartDate(DateTime date) {
    state.maybeWhen(
      loaded: (form) {
        // Äáº£m báº£o endDate khÃ´ng trÆ°á»›c startDate
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

  void updateTripIntents(List<String> intents) {
    state.maybeWhen(
      loaded: (form) {
        final valid = intents.where(kTripIntents.contains).toList();
        emit(
          TripPlannerState.loaded(
            tripForm: form.copyWith(
              tripIntent: valid.isEmpty ? null : valid.join(', '),
            ),
          ),
        );
      },
      orElse: () {},
    );
  }

  // â”€â”€ BÆ°á»›c 2: ThÃ nh viÃªn â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

  // â”€â”€ BÆ°á»›c 3: NgÃ¢n sÃ¡ch & áº¨m thá»±c â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

  // â”€â”€ Navigation â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

  // â”€â”€ Submit â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> submitTripPlan() async {
    final form = state.whenOrNull(loaded: (f) => f);
    if (form == null) return;

    // Validation
    if (form.departureLocationId == null || form.departureLocationId!.isEmpty) {
      emit(TripPlannerState.error('Vui lÃ²ng chá»n Ä‘iá»ƒm khá»Ÿi hÃ nh'));
      emit(TripPlannerState.loaded(tripForm: form));
      return;
    }
    if (form.destinationLocationId == null ||
        form.destinationLocationId!.isEmpty) {
      emit(TripPlannerState.error('Vui lÃ²ng chá»n Ä‘iá»ƒm Ä‘áº¿n'));
      emit(TripPlannerState.loaded(tripForm: form));
      return;
    }
    if (form.departureLocationId == form.destinationLocationId) {
      emit(
        TripPlannerState.error(
          'Äiá»ƒm khá»Ÿi hÃ nh vÃ  Ä‘iá»ƒm Ä‘áº¿n khÃ´ng Ä‘Æ°á»£c trÃ¹ng nhau',
        ),
      );
      emit(TripPlannerState.loaded(tripForm: form));
      return;
    }
    if (form.startDate == null) {
      emit(TripPlannerState.error('Vui lÃ²ng chá»n ngÃ y báº¯t Ä‘áº§u'));
      emit(TripPlannerState.loaded(tripForm: form));
      return;
    }
    if (form.endDate == null) {
      emit(TripPlannerState.error('Vui lÃ²ng chá»n ngÃ y káº¿t thÃºc'));
      emit(TripPlannerState.loaded(tripForm: form));
      return;
    }
    if (form.endDate!.isBefore(form.startDate!)) {
      emit(
        TripPlannerState.error(
          'NgÃ y káº¿t thÃºc khÃ´ng Ä‘Æ°á»£c trÆ°á»›c ngÃ y báº¯t Ä‘áº§u',
        ),
      );
      emit(TripPlannerState.loaded(tripForm: form));
      return;
    }
    final dailyStartTime = form.startTime ?? '07:00';
    final dailyEndTime = form.endTime ?? '22:00';
    if (!_isValidTimeRange(dailyStartTime, dailyEndTime)) {
      emit(
        TripPlannerState.error(
          'Giá» káº¿t thÃºc pháº£i sau giá» báº¯t Ä‘áº§u',
        ),
      );
      emit(TripPlannerState.loaded(tripForm: form));
      return;
    }
    final selectedTripIntents = _parseTripIntents(form.tripIntent);
    if (selectedTripIntents.any((intent) => !kTripIntents.contains(intent))) {
      emit(
        TripPlannerState.error('Má»¥c Ä‘Ã­ch chuyáº¿n Ä‘i khÃ´ng há»£p lá»‡'),
      );
      emit(TripPlannerState.loaded(tripForm: form));
      return;
    }
    if (form.adultCount < 1) {
      emit(
        TripPlannerState.error(
          'Chuyáº¿n Ä‘i pháº£i cÃ³ Ã­t nháº¥t 1 ngÆ°á»i lá»›n',
        ),
      );
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
          tripIntent: selectedTripIntents.isEmpty
              ? kTripIntents.first
              : selectedTripIntents.join(', '),
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

  // â”€â”€ Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

  List<String> _parseTripIntents(String? value) {
    if (value == null || value.trim().isEmpty) return const [];
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
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
