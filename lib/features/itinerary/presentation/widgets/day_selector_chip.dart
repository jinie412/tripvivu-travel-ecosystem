import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class DaySelectorChip extends StatelessWidget {
  final int dayNumber;
  final int locationCount;
  final bool isSelected;
  final VoidCallback onTap;

  const DaySelectorChip({
    super.key,
    required this.dayNumber,
    required this.locationCount,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 85,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFFF3F4F6)),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Column(
          children: [
            Text(
              '12/06', // Mock date
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.white70 : const Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Ngày $dayNumber',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : const Color(0xFF1C1C1E),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white24 : const Color(0xFFF3F4FB),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$locationCount',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
