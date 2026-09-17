import 'package:flutter/material.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';

class FoodPreferenceSection extends StatelessWidget {
  final List<String> selectedPreferences;
  final ValueChanged<String> onToggle;
  
  final List<String> availablePreferences = const [
    'Đặc sản địa phương',
    'Hải sản',
    'Món chay',
    'Đường phố',
    'Nhà hàng cao cấp',
  ];

  const FoodPreferenceSection({
    super.key,
    required this.selectedPreferences,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.restaurant, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'Sở thích ẩm thực',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ...availablePreferences.map((pref) {
              final isSelected = selectedPreferences.contains(pref);
              return GestureDetector(
                onTap: () => onToggle(pref),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.inputFill,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.inputBorder.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    pref,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }),
            // Thêm mới button
            GestureDetector(
              onTap: () {
                // Handle add new preference
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.inputBorder,
                    style: BorderStyle.solid,
                  ), // should use dashed boundary if available, but basic border is fine
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 16, color: AppColors.textSecondary),
                    SizedBox(width: 4),
                    Text(
                      'Thêm mới',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}