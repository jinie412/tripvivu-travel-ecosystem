import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/di/injection_container.dart';
import '../cubit/trip_planner_cubit.dart';
import '../cubit/trip_planner_state.dart';
import '../widgets/location_selector_card.dart';
import '../widgets/step_progress_bar.dart';
import '../widgets/transportation_selector.dart';
import '../widgets/trip_type_selector.dart';
import 'trip_planner_step2_screen.dart';

class TripPlannerScreen extends StatelessWidget {
  const TripPlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<TripPlannerCubit>(),
      child: const _TripPlannerView(),
    );
  }
}

class _TripPlannerView extends StatelessWidget {
  const _TripPlannerView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: AppSizes.s16, top: AppSizes.s4, bottom: AppSizes.s4),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: Column(
          children: [
            Text(
              'Tạo lịch trình mới',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: AppSizes.s2),
            Text(
              'BƯỚC 1/3',
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
              Navigator.of(context).pop();
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
          const SizedBox(width: AppSizes.s8),
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
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.s16, vertical: AppSizes.s8),
                    child: StepProgressBar(
                      currentStep: tripForm.currentStep,
                      totalSteps: 3,
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSizes.s24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bạn sẽ đi đâu?',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSizes.s12),
                          const Text(
                            'Điền thông tin địa điểm và phương tiện di chuyển của bạn cho chuyến du lịch trong nước.',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: AppSizes.s24),
                          TripTypeSelector(
                            selectedType: tripForm.tripType,
                            onChanged: (type) {
                              context.read<TripPlannerCubit>().updateTripType(type);
                            },
                          ),
                          const SizedBox(height: AppSizes.s32),
                          LocationSelectorCard(
                            departureLocation: tripForm.departureLocation,
                            destinationLocation: tripForm.destinationLocation,
                            onTapDeparture: () {
                              // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Open Location Picker for Departure')));
                              context.read<TripPlannerCubit>().updateDeparture("TP. Hồ Chí Minh");
                            },
                            onTapDestination: () {
                              context.read<TripPlannerCubit>().updateDestination("Hà Nội");
                            },
                            onSwap: () {
                              context.read<TripPlannerCubit>().swapLocations();
                            },
                          ),
                          const SizedBox(height: AppSizes.s32),
                          TransportationSelector(
                            selectedOption: tripForm.transportation,
                            onChanged: (transport) {
                              context.read<TripPlannerCubit>().updateTransportation(transport);
                            },
                          ),
                          const SizedBox(height: AppSizes.s64), // Space for button
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(AppSizes.s16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<TripPlannerCubit>().goNextStep();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider.value(
                              value: context.read<TripPlannerCubit>(),
                              child: const TripPlannerStep2Screen(),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size(double.infinity, AppSizes.appBarHeight),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.r16),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Tiếp tục',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: AppSizes.s8),
                          Icon(Icons.arrow_forward, color: Colors.white, size: AppSizes.iconMd),
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
