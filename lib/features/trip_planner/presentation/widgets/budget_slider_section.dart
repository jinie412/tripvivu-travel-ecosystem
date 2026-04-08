import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';

class BudgetSliderSection extends StatelessWidget {
  final double currentBudget;
  final ValueChanged<double> onChanged;

  const BudgetSliderSection({
    super.key,
    required this.currentBudget,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.money, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'Mức ngân sách',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.primary.withValues(alpha: 0.2),
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.1),
            trackHeight: 4.0,
          ),
          child: Slider(
            value: currentBudget,
            min: 500000,
            max: 10000000,
            divisions: 19, // steps of 500k
            onChanged: onChanged,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              formatCurrency.format(500000),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              formatCurrency.format(currentBudget),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              formatCurrency.format(10000000),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}