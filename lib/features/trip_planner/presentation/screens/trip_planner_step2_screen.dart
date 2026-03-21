import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../cubit/trip_planner_cubit.dart';
import '../cubit/trip_planner_state.dart';
import '../widgets/date_picking_field.dart';
import '../widgets/member_counter_card.dart';
import '../widgets/time_picking_card.dart';
import '../widgets/topic_selector.dart';
import 'trip_planner_step3_screen.dart';

class TripPlannerStep2Screen extends StatelessWidget {
  const TripPlannerStep2Screen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
          onPressed: () {
            context.read<TripPlannerCubit>().goPrevStep();
            Navigator.of(context).pop();
          },
        ),
        title: Column(
          children: [
            const Text(
              'Tạo lịch trình mới',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Bước 2/3',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
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
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Stack(
              children: [
                Container(
                  height: 4,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Container(
                  height: 4,
                  width: MediaQuery.of(context).size.width * 0.66,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: BlocBuilder<TripPlannerCubit, TripPlannerState>(
        builder: (context, state) {
          return state.maybeWhen(
            loaded: (tripForm) {
              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionTitle(title: 'THỜI GIAN CHUYẾN ĐI'),
                          const SizedBox(height: 16),
                          DatePickingField(
                            label: 'TỪ NGÀY',
                            date: tripForm.startDate,
                            onTap: () {
                              context.read<TripPlannerCubit>().updateStartDate(DateTime(2024, 6, 15));
                            },
                          ),
                          DatePickingField(
                            label: 'ĐẾN NGÀY',
                            date: tripForm.endDate,
                            onTap: () {
                              context.read<TripPlannerCubit>().updateEndDate(DateTime(2024, 6, 20));
                            },
                          ),
                          const SizedBox(height: 32),
                          const _SectionTitle(title: 'THỜI GIAN HOẠT ĐỘNG TRONG NGÀY'),
                          const SizedBox(height: 16),
                          TimePickingCard(
                            startTime: tripForm.startTime,
                            endTime: tripForm.endTime,
                            onTapStart: () {
                              context.read<TripPlannerCubit>().updateStartTime('07:00 AM');
                            },
                            onTapEnd: () {
                              context.read<TripPlannerCubit>().updateEndTime('11:00 PM');
                            },
                          ),
                          const SizedBox(height: 32),
                          const _SectionTitle(title: 'CHỦ ĐỀ CHUYẾN ĐI'),
                          const SizedBox(height: 16),
                          TopicSelector(
                            selectedTopic: tripForm.topic,
                            onTap: () {
                              context.read<TripPlannerCubit>().updateTopic('Khám phá & Trải nghiệm');
                            },
                          ),
                          const SizedBox(height: 32),
                          const _SectionTitle(title: 'SỐ LƯỢNG THÀNH VIÊN'),
                          const SizedBox(height: 16),
                          MemberCounterCard(
                            adultCount: tripForm.adultCount,
                            childCount: tripForm.childCount,
                            onAdultIncrease: () => context.read<TripPlannerCubit>().increaseAdults(),
                            onAdultDecrease: () => context.read<TripPlannerCubit>().decreaseAdults(),
                            onChildIncrease: () => context.read<TripPlannerCubit>().increaseChildren(),
                            onChildDecrease: () => context.read<TripPlannerCubit>().decreaseChildren(),
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
                        context.read<TripPlannerCubit>().goNextStep();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider.value(
                              value: context.read<TripPlannerCubit>(),
                              child: const TripPlannerStep3Screen(),
                            ),
                          ),
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
                            'Tiếp tục',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, color: Colors.white, size: 20),
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

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}
