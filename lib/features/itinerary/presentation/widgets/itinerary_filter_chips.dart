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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip(label: 'Tất cả', value: null),
                const SizedBox(width: 8),
                _chip(label: 'Sắp đi', value: ItineraryStatus.upcoming),
                const SizedBox(width: 8),
                _chip(label: 'Đang đi', value: ItineraryStatus.ongoing),
                const SizedBox(width: 8),
                _chip(label: 'Đã kết thúc', value: ItineraryStatus.completed),
                const SizedBox(width: 8),
                _chip(label: 'Chưa hoàn thành', value: ItineraryStatus.uncompleted),
                const SizedBox(width: 8),
                _chip(label: 'Đang tạo', value: ItineraryStatus.draft),
              ],
            ),
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
                _subChip(label: 'Chưa đánh giá', value: CompletedFilter.unrated),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _chip({required String label, required ItineraryStatus? value}) {
    final isActive = activeFilter == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primary : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppColors.textSecondary,
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
          color: isActive ? const Color(0xFFF1F5F9) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
