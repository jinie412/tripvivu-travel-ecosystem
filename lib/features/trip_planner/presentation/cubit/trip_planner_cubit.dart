import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:travel_advisor_mobile/core/error/budget_confirmation_required_exception.dart';
import 'package:travel_advisor_mobile/core/error/region_allocation_required_exception.dart';
import 'package:travel_advisor_mobile/core/utils/auth_utils.dart';
import 'package:travel_advisor_mobile/features/trip_planner/domain/entities/trip_form.dart';
import 'package:travel_advisor_mobile/features/trip_planner/domain/entities/trip_intent_options.dart';
import 'package:travel_advisor_mobile/features/trip_planner/domain/usecases/create_itinerary_usecase.dart';
import 'trip_planner_state.dart';

class TripPlannerCubit extends Cubit<TripPlannerState> {
  final CreateItineraryUseCase _createItinerary;

  /// Giữ gaItineraryId ngoài state (tránh tái gen Freezed) — chỉ có giá trị khi compare.
  String? lastGaItineraryId;

  /// Params/form của lần submit gần nhất — giữ ngoài state (tránh tái gen
  /// Freezed) để retryWithRecommendedBudget() có thể gửi lại đúng request đó
  /// với budget đã đổi, và để quay lại đúng form nếu request đó lỗi.
  CreateItineraryParams? _lastAttemptedParams;
  TripForm? _lastAttemptedForm;

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
      loaded: (form) => emit(
        TripPlannerState.loaded(tripForm: form.copyWith(startDate: date)),
      ),
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
        final normalized = _normalizeTripIntents(intents);
        emit(
          TripPlannerState.loaded(
            tripForm: form.copyWith(
              tripIntent: normalized.isEmpty ? null : normalized.join(', '),
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

  // [TRIP_NAME_INPUT] Cập nhật tên chuyến đi khi user gõ vào TextField
  void updateTripName(String name) {
    state.maybeWhen(
      loaded: (form) => emit(
        TripPlannerState.loaded(tripForm: form.copyWith(tripName: name)),
      ),
      orElse: () {},
    );
  }

  // [TRIP_NAME_INPUT] Lấy tên hiện tại hoặc tự sinh nếu chưa có, rồi lưu vào form
  String resolveOrGenerateTripName() {
    final form = state.whenOrNull(loaded: (f) => f);
    if (form == null) return '';
    if (form.tripName != null && form.tripName!.isNotEmpty)
      return form.tripName!;
    final generated = _generateTripName(form);
    emit(TripPlannerState.loaded(tripForm: form.copyWith(tripName: generated)));
    return generated;
  }

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

  // ── Validation per step ─────────────────────────────────────────────────────

  String? validateStep1() {
    final form = state.whenOrNull(loaded: (f) => f);
    if (form == null) return null;
    if (form.departureLocationId == null || form.departureLocationId!.isEmpty) {
      return 'Vui lòng chọn điểm khởi hành';
    }
    if (form.destinationLocationId == null ||
        form.destinationLocationId!.isEmpty) {
      return 'Vui lòng chọn điểm đến';
    }
    return null;
  }

  String? validateStep2() {
    final form = state.whenOrNull(loaded: (f) => f);
    if (form == null) return null;
    if (form.startDate == null) return 'Vui lòng chọn ngày bắt đầu';
    if (form.endDate == null) return 'Vui lòng chọn ngày kết thúc';
    if (form.endDate!.isBefore(form.startDate!)) {
      return 'Ngày kết thúc không được trước ngày bắt đầu';
    }
    if (form.endDate!.difference(form.startDate!).inDays > 7) {
      return 'Chuyến đi tối đa 7 ngày';
    }
    if (form.tripIntent == null || form.tripIntent!.trim().isEmpty) {
      return 'Vui lòng chọn ít nhất một loại hình du lịch';
    }
    return null;
  }

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
    if (form.endDate!.difference(form.startDate!).inDays > 7) {
      emit(TripPlannerState.error('Chuyến đi tối đa 7 ngày'));
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

    final params = CreateItineraryParams(
      userId: await AuthUtils.requireCurrentUserId(),
      tripType: _tripTypeToApi(form.tripType),
      departureLocationId: form.departureLocationId!,
      destinationLocationId: form.destinationLocationId!,
      transportMode: _transportToApi(form.transportation),
      startDate: _formatDate(form.startDate),
      endDate: _formatDate(form.endDate),
      dailyStartTime: dailyStartTime,
      dailyEndTime: dailyEndTime,
      tripIntent: selectedTripIntents.isEmpty
          ? kGeneralTripIntent
          : selectedTripIntents.join(', '),
      adultCount: form.adultCount,
      childCount: form.childCount,
      budget: form.budget,
      foodPreferences: form.foodPreferences,
      tripName: (form.tripName != null && form.tripName!.isNotEmpty)
          ? form.tripName
          : _generateTripName(form),
    );
    await _submitParams(params, form);
  }

  /// Gọi lại request tạo lịch trình gần nhất với budget = recommendedBudget
  /// từ state budgetConfirmationRequired — người dùng chọn "Dùng mức đề xuất".
  Future<void> retryWithRecommendedBudget() async {
    final recommendedBudget = state.whenOrNull(
      budgetConfirmationRequired: (_, _, _, recommendedBudget, _) =>
          recommendedBudget,
    );
    final lastParams = _lastAttemptedParams;
    final lastForm = _lastAttemptedForm;
    if (recommendedBudget == null || lastParams == null || lastForm == null) {
      return;
    }
    await _submitParams(
      lastParams.copyWith(budget: recommendedBudget),
      lastForm.copyWith(budget: recommendedBudget),
    );
  }

  /// Gọi lại request tạo lịch trình gần nhất sau khi người dùng đã chốt số
  /// ngày cho từng vùng ở màn wizard phân bổ vùng (từ state
  /// regionAllocationRequired).
  Future<void> submitRegionAllocations(
    List<RegionAllocationInput> allocations,
  ) async {
    final lastParams = _lastAttemptedParams;
    final lastForm = _lastAttemptedForm;
    if (lastParams == null || lastForm == null) return;
    await _submitParams(
      lastParams.copyWith(regionAllocations: allocations),
      lastForm,
    );
  }

  Future<void> _submitParams(
    CreateItineraryParams params,
    TripForm form,
  ) async {
    _lastAttemptedParams = params;
    _lastAttemptedForm = form;
    emit(const TripPlannerState.generating());
    try {
      final result = await _createItinerary(params);
      lastGaItineraryId = result.gaItineraryId;
      emit(TripPlannerState.success(itineraryId: result.itineraryId));
    } on BudgetConfirmationRequiredException catch (e) {
      emit(
        TripPlannerState.budgetConfirmationRequired(
          message: e.message,
          userBudget: e.userBudget,
          calculatedCost: e.calculatedCost,
          recommendedBudget: e.recommendedBudget,
          participantCount: e.participantCount,
        ),
      );
    } on RegionAllocationRequiredException catch (e) {
      emit(
        TripPlannerState.regionAllocationRequired(
          message: e.message,
          regions: e.regions,
          numDays: e.numDays,
          estimatedTotalDays: e.estimatedTotalDays,
        ),
      );
    } catch (e) {
      emit(TripPlannerState.error(e.toString()));
      emit(TripPlannerState.loaded(tripForm: form));
    }
  }

  // â”€â”€ Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  // [TRIP_NAME_INPUT] Tự sinh tên từ điểm đến + khoảng ngày, VD: "Đà Nẵng • 10–13/06"
  String _generateTripName(TripForm form) {
    final dest = form.destinationLocation ?? '';
    if (form.startDate == null) return dest;
    final startDay = form.startDate!.day;
    final startMonth = form.startDate!.month;
    final endDay = form.endDate?.day;
    final endMonth = form.endDate?.month;
    final dateRange = (endDay != null && endMonth != null)
        ? '$startDay–$endDay/$startMonth'
        : '$startDay/$startMonth';
    return dest.isNotEmpty ? '$dest • $dateRange' : dateRange;
  }

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

  List<String> _parseTripIntents(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    final seen = <String>{};
    final parsed = raw
        .split(',')
        .map((v) => v.trim())
        .where(kTripIntents.contains)
        .where(seen.add)
        .toList();
    if (parsed.length > 1 && parsed.contains(kGeneralTripIntent)) {
      return parsed.where((v) => v != kGeneralTripIntent).toList();
    }
    return parsed;
  }

  List<String> _normalizeTripIntents(List<String> intents) {
    if (intents.isEmpty) return const [];
    final seen = <String>{};
    final valid = intents.where(kTripIntents.contains).where(seen.add).toList();
    // Safety net: nếu general trộn với specific, bỏ general
    if (valid.length > 1 && valid.contains(kGeneralTripIntent)) {
      return valid
          .where((v) => v != kGeneralTripIntent)
          .take(kMaxTripIntents)
          .toList();
    }
    return valid.take(kMaxTripIntents).toList();
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
