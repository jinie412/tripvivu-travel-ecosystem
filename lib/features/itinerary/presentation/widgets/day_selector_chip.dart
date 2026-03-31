import 'package:flutter/material.dart';

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
    // Teal color from the image (Roughly AppColors.primary or teal)
    final activeColor = isSelected ? const Color(0xFF4FB3BF) : const Color(0xFF94A3B8);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ngày $dayNumber',
              style: TextStyle(
                fontSize: 18,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: activeColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${15 + dayNumber}/6', // Simplified mock date logic from image
              style: TextStyle(
                fontSize: 12,
                color: activeColor.withAlpha(isSelected ? 255 : 180),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 24,
              height: 3,
              decoration: BoxDecoration(
                color: isSelected ? activeColor : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}