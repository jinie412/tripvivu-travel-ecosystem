import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:travel_advisor_mobile/core/di/injection_container.dart';
import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/cubit/itinerary_cubit.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/screens/itinerary_summary_screen.dart';
import 'package:travel_advisor_mobile/features/trip_planner/presentation/cubit/trip_planner_cubit.dart';
import 'package:travel_advisor_mobile/features/trip_planner/presentation/cubit/trip_planner_state.dart';
import 'package:travel_advisor_mobile/features/trip_planner/presentation/widgets/budget_slider_section.dart';
import '../widgets/step_progress_bar.dart';

class TripPlannerStep3Screen extends StatelessWidget {
  const TripPlannerStep3Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripPlannerCubit, TripPlannerState>(
      listener: (context, state) {
        state.whenOrNull(
          generating: () => _showLoadingDialog(context),
          success: (itineraryId) {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider(
                  create: (_) {
                    final cubit = sl<ItineraryCubit>();
                    cubit.loadData().then((_) => cubit.selectItinerary(itineraryId));
                    return cubit;
                  },
                  child: ItinerarySummaryScreen(itineraryId: itineraryId),
                ),
              ),
              (route) => route.isFirst,
            );
          },
          error: (msg) {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi: $msg'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        );
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            centerTitle: true,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
              child: Container(
                decoration: const BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
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
              children: [
                const Text('Tạo lịch trình mới', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('BƯỚC 3/3', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                child: const Text('Hủy', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14)),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: state.maybeWhen(
            loaded: (tripForm) => Column(
              children: [
                Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: StepProgressBar(currentStep: tripForm.currentStep, totalSteps: 3),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ngân sách',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Thiết lập ngân sách cho chuyến đi của bạn.',
                          style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                        ),
                        const SizedBox(height: 32),
                        BudgetSliderSection(
                          currentBudget: tripForm.budget,
                          onChanged: (v) => context.read<TripPlannerCubit>().updateBudget(v),
                        ),
                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppColors.background,
                  child: ElevatedButton(
                    onPressed: () => context.read<TripPlannerCubit>().submitTripPlan(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Hoàn thành', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                        SizedBox(width: 8),
                        Icon(Icons.check_circle, color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        );
      },
    );
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'AI đang tạo lịch trình...',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 4),
              Text(
                'Vui lòng chờ trong giây lát',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
