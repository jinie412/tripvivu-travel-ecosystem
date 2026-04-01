import 'package:flutter_bloc/flutter_bloc.dart';
import 'trip_planner_state.dart';

import 'package:travel_advisor_mobile/features/trip_planner/domain/entities/trip_form.dart';

class TripPlannerCubit extends Cubit<TripPlannerState> {
  TripPlannerCubit() : super(const TripPlannerState.loaded(tripForm: TripForm()));

  void updateTripType(TripType type) {
    state.maybeWhen(
      loaded: (form) {
        emit(TripPlannerState.loaded(tripForm: form.copyWith(tripType: type)));
      },
      orElse: () {},
    );
  }

  void updateDeparture(String location) {
    state.maybeWhen(
      loaded: (form) {
        emit(TripPlannerState.loaded(tripForm: form.copyWith(departureLocation: location)));
      },
      orElse: () {},
    );
  }

  void updateDestination(String location) {
    state.maybeWhen(
      loaded: (form) {
        emit(TripPlannerState.loaded(tripForm: form.copyWith(destinationLocation: location)));
      },
      orElse: () {},
    );
  }

  void swapLocations() {
    state.maybeWhen(
      loaded: (form) {
        emit(TripPlannerState.loaded(
            tripForm: form.copyWith(
          departureLocation: form.destinationLocation,
          destinationLocation: form.departureLocation,
        )));
      },
      orElse: () {},
    );
  }

  void updateTransportation(Transportation transport) {
    state.maybeWhen(
      loaded: (form) {
        emit(TripPlannerState.loaded(tripForm: form.copyWith(transportation: transport)));
      },
      orElse: () {},
    );
  }

  void updateStartDate(DateTime date) {
    state.maybeWhen(
      loaded: (form) => emit(TripPlannerState.loaded(tripForm: form.copyWith(startDate: date))),
      orElse: () {},
    );
  }

  void updateEndDate(DateTime date) {
    state.maybeWhen(
      loaded: (form) => emit(TripPlannerState.loaded(tripForm: form.copyWith(endDate: date))),
      orElse: () {},
    );
  }

  void updateStartTime(String time) {
    state.maybeWhen(
      loaded: (form) => emit(TripPlannerState.loaded(tripForm: form.copyWith(startTime: time))),
      orElse: () {},
    );
  }

  void updateEndTime(String time) {
    state.maybeWhen(
      loaded: (form) => emit(TripPlannerState.loaded(tripForm: form.copyWith(endTime: time))),
      orElse: () {},
    );
  }

  void updateTopic(String topic) {
    state.maybeWhen(
      loaded: (form) => emit(TripPlannerState.loaded(tripForm: form.copyWith(topic: topic))),
      orElse: () {},
    );
  }

  void increaseAdults() {
    state.maybeWhen(
      loaded: (form) => emit(TripPlannerState.loaded(tripForm: form.copyWith(adultCount: form.adultCount + 1))),
      orElse: () {},
    );
  }

  void decreaseAdults() {
    state.maybeWhen(
      loaded: (form) {
        if (form.adultCount > 1) {
          emit(TripPlannerState.loaded(tripForm: form.copyWith(adultCount: form.adultCount - 1)));
        }
      },
      orElse: () {},
    );
  }

  void increaseChildren() {
    state.maybeWhen(
      loaded: (form) => emit(TripPlannerState.loaded(tripForm: form.copyWith(childCount: form.childCount + 1))),
      orElse: () {},
    );
  }

  void decreaseChildren() {
    state.maybeWhen(
      loaded: (form) {
        if (form.childCount > 0) {
          emit(TripPlannerState.loaded(tripForm: form.copyWith(childCount: form.childCount - 1)));
        }
      },
      orElse: () {},
    );
  }

  void goNextStep() {
    state.maybeWhen(
      loaded: (form) {
        if (form.currentStep < 3) {
          emit(TripPlannerState.loaded(tripForm: form.copyWith(currentStep: form.currentStep + 1)));
        }
      },
      orElse: () {},
    );
  }

  void goPrevStep() {
    state.maybeWhen(
      loaded: (form) {
        if (form.currentStep > 1) {
          emit(TripPlannerState.loaded(tripForm: form.copyWith(currentStep: form.currentStep - 1)));
        }
      },
      orElse: () {},
    );
  }

  void updateBudget(double amount) {
    state.maybeWhen(
      loaded: (form) => emit(TripPlannerState.loaded(tripForm: form.copyWith(budget: amount))),
      orElse: () {},
    );
  }

  void toggleFoodPreference(String preference) {
    state.maybeWhen(
      loaded: (form) {
        final currentList = List<String>.from(form.foodPreferences);
        if (currentList.contains(preference)) {
          currentList.remove(preference);
        } else {
          currentList.add(preference);
        }
        emit(TripPlannerState.loaded(tripForm: form.copyWith(foodPreferences: currentList)));
      },
      orElse: () {},
    );
  }

  void finishTripPlan() {
    state.maybeWhen(
      loaded: (form) {
        // Validation check if needed, then submit
        // emit(TripPlannerState.loading());
        // fake request wait...
        
        // Return to home or show success dialog in UI
      },
      orElse: () {},
    );
  }
}