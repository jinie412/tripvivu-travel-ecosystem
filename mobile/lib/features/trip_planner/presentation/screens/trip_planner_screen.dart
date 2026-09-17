import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:travel_advisor_mobile/core/constants/app_sizes.dart';
import 'package:travel_advisor_mobile/core/di/injection_container.dart';
import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/features/city/domain/usecases/search_cities_usecase.dart';
import 'package:travel_advisor_mobile/features/trip_planner/presentation/cubit/trip_planner_cubit.dart';
import 'package:travel_advisor_mobile/features/trip_planner/presentation/cubit/trip_planner_state.dart';
import 'package:travel_advisor_mobile/features/trip_planner/presentation/widgets/city_search_bottom_sheet.dart';
import 'package:travel_advisor_mobile/features/trip_planner/presentation/widgets/location_selector_card.dart';
import 'package:travel_advisor_mobile/features/trip_planner/presentation/widgets/step_progress_bar.dart';
import 'package:travel_advisor_mobile/features/trip_planner/presentation/widgets/transportation_selector.dart';
import 'trip_planner_step2_screen.dart';

class TripPlannerScreen extends StatelessWidget {
  const TripPlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TripPlannerCubit>(),
      child: const _TripPlannerView(),
    );
  }
}

class _TripPlannerView extends StatelessWidget {
  const _TripPlannerView();

  Future<void> _pickCity(
    BuildContext context, {
    required bool isDeparture,
  }) async {
    final city = await CitySearchBottomSheet.show(
      context,
      searchCitiesUseCase: sl<SearchCitiesUseCase>(),
      title: isDeparture ? 'Chọn điểm khởi hành' : 'Chọn điểm đến',
      destinationOnly: !isDeparture,
    );
    if (city == null || !context.mounted) return;

    final cubit = context.read<TripPlannerCubit>();
    if (isDeparture) {
      cubit.updateDeparture(city.name, city.id);
    } else {
      cubit.updateDestination(city.name, city.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.premiumBackground,
      appBar: AppBar(
        backgroundColor: AppColors.premiumSurface,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(
            left: AppSizes.s16,
            top: AppSizes.s4,
            bottom: AppSizes.s4,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.premiumSoftBlue,
              borderRadius: BorderRadius.circular(13),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.chevron_left,
                color: AppColors.premiumNavy,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: Column(
          children: [
            const Text(
              'Tạo lịch trình mới',
              style: TextStyle(
                color: AppColors.premiumNavy,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSizes.s2),
            Text(
              'BƯỚC 1/3',
              style: TextStyle(
                color: AppColors.premiumMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Hủy',
              style: TextStyle(
                color: AppColors.premiumBlue,
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
            loaded: (tripForm) => Column(
              children: [
                Container(
                  color: AppColors.premiumSurface,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.s16,
                    vertical: AppSizes.s8,
                  ),
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
                            color: AppColors.premiumNavy,
                          ),
                        ),
                        const SizedBox(height: AppSizes.s12),
                        Text(
                          'Chọn địa điểm khởi hành, điểm đến và phương tiện di chuyển.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.premiumMuted,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: AppSizes.s24),
                        LocationSelectorCard(
                          departureLocation: tripForm.departureLocation,
                          destinationLocation: tripForm.destinationLocation,
                          onTapDeparture: () =>
                              _pickCity(context, isDeparture: true),
                          onTapDestination: () =>
                              _pickCity(context, isDeparture: false),
                          onSwap: () =>
                              context.read<TripPlannerCubit>().swapLocations(),
                        ),
                        const SizedBox(height: AppSizes.s32),
                        TransportationSelector(
                          selectedOption: tripForm.transportation,
                          onChanged: (t) => context
                              .read<TripPlannerCubit>()
                              .updateTransportation(t),
                          selectedType: tripForm.tripType,
                          onTypeChanged: (t) => context
                              .read<TripPlannerCubit>()
                              .updateTripType(t),
                        ),
                        const SizedBox(height: AppSizes.s64),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(AppSizes.s16),
                  color: AppColors.premiumBackground,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primary],
                      ),
                      borderRadius: BorderRadius.circular(AppSizes.r16),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        final cubit = context.read<TripPlannerCubit>();
                        final error = cubit.validateStep1();
                        if (error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(error),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }
                        cubit.goNextStep();
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
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        minimumSize: const Size(
                          double.infinity,
                          AppSizes.appBarHeight,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.r16),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
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
                          Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: AppSizes.iconMd,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            orElse: () => const Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}
