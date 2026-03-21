import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../cubit/trip_planner_cubit.dart';
import '../cubit/trip_planner_state.dart';
import '../widgets/budget_slider_section.dart';
import '../widgets/food_preference_section.dart';
import '../widgets/step_progress_bar.dart'; 
import '../../../../core/di/injection_container.dart';
import '../../../itinerary/presentation/cubit/itinerary_cubit.dart';
import '../../../itinerary/presentation/screens/itinerary_summary_screen.dart';

class TripPlannerStep3Screen extends StatelessWidget {
  const TripPlannerStep3Screen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 4, bottom: 4),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
              onPressed: () {
                context.read<TripPlannerCubit>().goPrevStep();
                Navigator.of(context).pop();
              },
            ),
          ),
        ),
        title: Column(
          children: const [
            Text(
              'Tạo lịch trình mới',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'BƯỚC 3/3',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text(
              'Hủy',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<TripPlannerCubit, TripPlannerState>(
        builder: (context, state) {
          return state.maybeWhen(
            loaded: (tripForm) {
              return Column(
                children: [
                  Container(
                    color: AppColors.surface,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: StepProgressBar(
                      currentStep: tripForm.currentStep,
                      totalSteps: 3,
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sở thích & Ngân sách',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Tùy chỉnh chuyến đi của bạn để nhận được lịch trình phù hợp nhất.',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 32),
                          BudgetSliderSection(
                            currentBudget: tripForm.budget,
                            onChanged: (value) {
                              context.read<TripPlannerCubit>().updateBudget(value);
                            },
                          ),
                          const SizedBox(height: 40),
                          FoodPreferenceSection(
                            selectedPreferences: tripForm.foodPreferences,
                            onToggle: (pref) {
                              context.read<TripPlannerCubit>().toggleFoodPreference(pref);
                            },
                          ),
                          const SizedBox(height: 60), // Space for button
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<TripPlannerCubit>().finishTripPlan();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider(
                              create: (_) {
                                final cubit = sl<ItineraryCubit>();
                                cubit.loadData().then((_) => cubit.selectItinerary('itin-001'));
                                return cubit;
                              },
                              child: const ItinerarySummaryScreen(itineraryId: 'itin-001'),
                            ),
                          ),
                          (route) => route.isFirst,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Hoàn thành',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.check_circle, color: Colors.white, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
            orElse: () => const Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}

class _DashedBorderContainer extends StatelessWidget {
  final Widget child;
  const _DashedBorderContainer({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
