import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/survey_entity.dart';

part 'survey_cubit.freezed.dart';

@freezed
class SurveyState with _$SurveyState {
  const factory SurveyState.initial({
    @Default(0) int currentStep,
    @Default(SurveyEntity()) SurveyEntity data,
  }) = _Initial;
  
  const factory SurveyState.loading({
    required int currentStep,
    required SurveyEntity data,
  }) = _Loading;
  
  const factory SurveyState.success({
    required int currentStep,
    required SurveyEntity data,
  }) = _Success;

  const factory SurveyState.error({
    required int currentStep,
    required SurveyEntity data,
    required String message,
  }) = _Error;
}

class SurveyCubit extends Cubit<SurveyState> {
  SurveyCubit() : super(const SurveyState.initial());

  bool checkCurrentStepValid() {
    final step = state.currentStep;
    final data = state.data;
    
    if (step == 0) return true; // Welcome step is always valid
    
    if (step == 1) {
      // Basic info: Age (1-120) and Gender required
      return data.age != null && 
             data.age! > 0 && 
             data.age! < 120 && 
             data.gender != null;
    }
    
    if (step == 2) {
      // Interests: At least one interest required
      return data.interests.isNotEmpty;
    }
    
    return false;
  }

  void nextStep() {
    if (!checkCurrentStepValid()) return;

    state.maybeWhen(
      initial: (step, data) {
        if (step < 2) {
          emit(SurveyState.initial(currentStep: step + 1, data: data));
        } else {
          submitSurvey();
        }
      },
      orElse: () {},
    );
  }

  void prevStep() {
    state.maybeWhen(
      initial: (step, data) {
        if (step > 0) {
          emit(SurveyState.initial(currentStep: step - 1, data: data));
        }
      },
      orElse: () {},
    );
  }

  void updateAge(int age) {
    state.maybeWhen(
      initial: (step, data) {
        emit(SurveyState.initial(currentStep: step, data: data.copyWith(age: age)));
      },
      orElse: () {},
    );
  }

  void updateGender(String gender) {
    state.maybeWhen(
      initial: (step, data) {
        emit(SurveyState.initial(currentStep: step, data: data.copyWith(gender: gender)));
      },
      orElse: () {},
    );
  }

  void toggleInterest(String interest) {
    state.maybeWhen(
      initial: (step, data) {
        final interests = List<String>.from(data.interests);
        if (interests.contains(interest)) {
          interests.remove(interest);
        } else {
          interests.add(interest);
        }
        emit(SurveyState.initial(currentStep: step, data: data.copyWith(interests: interests)));
      },
      orElse: () {},
    );
  }

  Future<void> submitSurvey() async {
    final currentData = state.data;
    emit(SurveyState.loading(currentStep: state.currentStep, data: currentData));
    
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 800));
    
    emit(SurveyState.success(currentStep: state.currentStep, data: currentData));
  }
}
