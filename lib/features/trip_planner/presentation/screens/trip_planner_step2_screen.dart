import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/features/trip_planner/domain/entities/trip_intent_options.dart';
import 'package:travel_advisor_mobile/features/trip_planner/presentation/cubit/trip_planner_cubit.dart';
import 'package:travel_advisor_mobile/features/trip_planner/presentation/cubit/trip_planner_state.dart';
import 'package:travel_advisor_mobile/features/trip_planner/presentation/widgets/date_picking_field.dart';
import 'package:travel_advisor_mobile/features/trip_planner/presentation/widgets/member_counter_card.dart';
import 'package:travel_advisor_mobile/features/trip_planner/presentation/widgets/time_picking_card.dart';
import 'trip_planner_step3_screen.dart';

class TripPlannerStep2Screen extends StatelessWidget {
  const TripPlannerStep2Screen({super.key});

  // â”€â”€ Pickers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _pickDate(
    BuildContext context, {
    required bool isStart,
    required DateTime? currentStart,
    required DateTime? currentEnd,
  }) async {
    const kMaxTripDays = 7;
    final now = DateTime.now();
    final firstDate = isStart ? now : (currentStart ?? now);
    final lastDate = !isStart && currentStart != null
        ? currentStart.add(const Duration(days: kMaxTripDays))
        : DateTime(now.year + 2);
    final rawInitial = isStart
        ? (currentStart ?? now)
        : (currentEnd ?? (currentStart ?? now).add(const Duration(days: 1)));
    final initialDate = rawInitial.isBefore(firstDate)
        ? firstDate
        : rawInitial.isAfter(lastDate)
        ? lastDate
        : rawInitial;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('vi'),
    );
    if (picked == null || !context.mounted) return;

    final cubit = context.read<TripPlannerCubit>();
    if (isStart) {
      cubit.updateStartDate(picked);
    } else {
      cubit.updateEndDate(picked);
    }
  }

  Future<void> _pickTripIntent(BuildContext context, String? current) async {
    final currentList = _parseTripIntents(current);
    final picked = await showModalBottomSheet<List<String>>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _TripIntentSheet(current: currentList),
    );
    if (picked == null || !context.mounted) return;
    context.read<TripPlannerCubit>().updateTripIntents(picked);
  }

  List<String> _parseTripIntents(String? value) {
    if (value == null || value.trim().isEmpty) return const [];
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static String _formatTripIntentLabel(List<String> selected) {
    if (selected.isEmpty) return 'Chọn loại hình du lịch';
    if (selected.length <= 2) return selected.join(', ');
    return '${selected.length} loại hình đã chọn';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.premiumBackground,
      appBar: AppBar(
        backgroundColor: AppColors.premiumSurface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left,
            color: AppColors.premiumNavy,
            size: 28,
          ),
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
                color: AppColors.premiumNavy,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Bước 2/3',
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
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            child: const Text(
              'Hủy',
              style: TextStyle(
                color: AppColors.premiumBlue,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Stack(
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.premiumBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: 0.66,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.premiumBlue,
                      borderRadius: BorderRadius.circular(2),
                    ),
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
            loaded: (tripForm) => Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionTitle(title: 'THỜI GIAN CHUYẾN ĐI'),
                        const SizedBox(height: 16),
                        DatePickingField(
                          label: 'TỪ NGÀY',
                          date: tripForm.startDate,
                          onTap: () => _pickDate(
                            context,
                            isStart: true,
                            currentStart: tripForm.startDate,
                            currentEnd: tripForm.endDate,
                          ),
                        ),
                        DatePickingField(
                          label: 'ĐẾN NGÀY',
                          date: tripForm.endDate,
                          onTap: () => _pickDate(
                            context,
                            isStart: false,
                            currentStart: tripForm.startDate,
                            currentEnd: tripForm.endDate,
                          ),
                        ),
                        const SizedBox(height: 32),
                        const _SectionTitle(
                          title: 'THỜI GIAN HOẠT ĐỘNG TRONG NGÀY',
                        ),
                        const SizedBox(height: 16),
                        TimePickingCard(
                          startTime: tripForm.startTime,
                          endTime: tripForm.endTime,
                          onStartChanged: (t) => context
                              .read<TripPlannerCubit>()
                              .updateStartTime(t),
                          onEndChanged: (t) =>
                              context.read<TripPlannerCubit>().updateEndTime(t),
                        ),
                        const SizedBox(height: 32),
                        const _SectionTitle(title: 'LOẠI HÌNH DU LỊCH'),
                        const SizedBox(height: 16),
                        _TripIntentButton(
                          selected: _parseTripIntents(tripForm.tripIntent),
                          label: _formatTripIntentLabel(
                            _parseTripIntents(tripForm.tripIntent),
                          ),
                          onTap: () =>
                              _pickTripIntent(context, tripForm.tripIntent),
                        ),
                        const SizedBox(height: 32),
                        const _SectionTitle(title: 'SỐ LƯỢNG THÀNH VIÊN'),
                        const SizedBox(height: 16),
                        MemberCounterCard(
                          adultCount: tripForm.adultCount,
                          childCount: tripForm.childCount,
                          onAdultIncrease: () =>
                              context.read<TripPlannerCubit>().increaseAdults(),
                          onAdultDecrease: () =>
                              context.read<TripPlannerCubit>().decreaseAdults(),
                          onChildIncrease: () => context
                              .read<TripPlannerCubit>()
                              .increaseChildren(),
                          onChildDecrease: () => context
                              .read<TripPlannerCubit>()
                              .decreaseChildren(),
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
                    onPressed: () {
                      final cubit = context.read<TripPlannerCubit>();
                      final error = cubit.validateStep2();
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
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
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

// â”€â”€ Trip Intent selector button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _TripIntentButton extends StatelessWidget {
  final List<String> selected;
  final String label;
  final VoidCallback onTap;

  const _TripIntentButton({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelection = selected.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.inputBorder.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.explore_outlined, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: hasSelection
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ Trip Intent bottom sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _TripIntentSheet extends StatefulWidget {
  final List<String> current;
  const _TripIntentSheet({required this.current});

  @override
  State<_TripIntentSheet> createState() => _TripIntentSheetState();
}

class _TripIntentSheetState extends State<_TripIntentSheet> {
  late final List<String> _selected = List.of(widget.current);

  void _toggle(String intent) {
    setState(() {
      if (intent == kGeneralTripIntent) {
        if (_selected.contains(kGeneralTripIntent)) {
          _selected.clear();
        } else {
          _selected
            ..clear()
            ..add(kGeneralTripIntent);
        }
        return;
      }
      // Specific intent: bỏ general nếu đang có
      _selected.remove(kGeneralTripIntent);
      if (_selected.contains(intent)) {
        _selected.remove(intent);
      } else if (_selected.length < kMaxTripIntents) {
        _selected.add(intent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.inputBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Mục đích chuyến đi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Có thể chọn nhiều (tối đa 3)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: kTripIntents.map((intent) {
                    final isSelected = _selected.contains(intent);
                    final atMax =
                        _selected.length >= kMaxTripIntents &&
                        !_selected.contains(kGeneralTripIntent);
                    final canToggle =
                        isSelected || intent == kGeneralTripIntent || !atMax;
                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: canToggle ? (_) => _toggle(intent) : null,
                      activeColor: AppColors.primary,
                      checkColor: Colors.white,
                      controlAffinity: ListTileControlAffinity.trailing,
                      title: Text(
                        intent,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? AppColors.primary
                              : canToggle
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _selected.clear()),
                      child: const Text('Xóa chọn'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.of(context).pop(List.of(_selected)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Áp dụng'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// â”€â”€ Section title â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

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
