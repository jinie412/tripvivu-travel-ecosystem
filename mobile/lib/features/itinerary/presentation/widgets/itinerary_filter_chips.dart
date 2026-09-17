import 'package:flutter/material.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/cubit/itinerary_state.dart';

/// Hàng nút Filter (Chip) — Tất cả · Sắp đi · Đã đi · Nháp
///
/// Khi bấm vào chip, gọi [onChanged] với giá trị [ItineraryStatus?].
/// Truyền `null` nghĩa là "Tất cả".
class ItineraryFilterChips extends StatelessWidget {
  final ItineraryStatus? activeFilter;
  final CompletedFilter activeSubFilter;
  final ValueChanged<ItineraryStatus?> onChanged;
  final ValueChanged<CompletedFilter> onSubFilterChanged;

  const ItineraryFilterChips({
    super.key,
    required this.activeFilter,
    required this.activeSubFilter,
    required this.onChanged,
    required this.onSubFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _chip(label: 'Tất cả', value: null),
              _chip(label: 'Sắp đi', value: ItineraryStatus.upcoming),
              _chip(label: 'Đang đi', value: ItineraryStatus.ongoing),
              _chip(label: 'Đã kết thúc', value: ItineraryStatus.completed),
              _chip(
                label: 'Chưa hoàn thành',
                value: ItineraryStatus.uncompleted,
              ),
            ],
          ),
        ),
        if (activeFilter == ItineraryStatus.completed) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _subChip(label: 'Tất cả', value: CompletedFilter.all),
                const SizedBox(width: 8),
                _subChip(label: 'Đã đánh giá', value: CompletedFilter.rated),
                const SizedBox(width: 8),
                _subChip(
                  label: 'Chưa đánh giá',
                  value: CompletedFilter.unrated,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _chip({required String label, required ItineraryStatus? value}) {
    final isActive = activeFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(
                    colors: [
                      AppColors.premiumBlue,
                      AppColors.premiumTeal,
                    ],
                  )
                : null,
            color: isActive ? null : AppColors.premiumSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive
                  ? Colors.transparent
                  : AppColors.premiumBorder,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.premiumBlue.withValues(alpha: .2),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              color: isActive ? Colors.white : AppColors.premiumMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _subChip({required String label, required CompletedFilter value}) {
    final isActive = activeSubFilter == value;
    return GestureDetector(
      onTap: () => onSubFilterChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [AppColors.premiumBlue, AppColors.premiumTeal],
                )
              : null,
          color: isActive ? null : AppColors.premiumSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? Colors.transparent : AppColors.premiumBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? Colors.white : AppColors.premiumMuted,
          ),
        ),
      ),
    );
  }
}
