import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/itinerary_entity.dart';

/// Hàng nút Filter (Chip) — Tất cả · Sắp đi · Đã đi · Nháp
///
/// Khi bấm vào chip, gọi [onChanged] với giá trị [ItineraryStatus?].
/// Truyền `null` nghĩa là "Tất cả".
class ItineraryFilterChips extends StatelessWidget {
  final ItineraryStatus? activeFilter;
  final ValueChanged<ItineraryStatus?> onChanged;

  const ItineraryFilterChips({
    super.key,
    required this.activeFilter,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _chip(label: 'Tất cả', value: null),
          const SizedBox(width: 8),
          _chip(label: 'Sắp đi', value: ItineraryStatus.upcoming),
          const SizedBox(width: 8),
          _chip(label: 'Đã đi', value: ItineraryStatus.completed),
          const SizedBox(width: 8),
          _chip(label: 'Nháp', value: ItineraryStatus.draft),
        ],
      ),
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
}
