import 'package:flutter/material.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/features/trip_planner/domain/entities/trip_form.dart';

class TransportationSelector extends StatelessWidget {
  final Transportation selectedOption;
  final ValueChanged<Transportation> onChanged;
  final TripType? selectedType;
  final ValueChanged<TripType>? onTypeChanged;

  const TransportationSelector({
    super.key,
    required this.selectedOption,
    required this.onChanged,
    this.selectedType,
    this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phương tiện di chuyển',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.premiumNavy,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildItem(
                title: 'Ô tô',
                icon: Icons.directions_car_filled_rounded,
                isSelected: selectedOption == Transportation.car,
                onTap: () => onChanged(Transportation.car),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildItem(
                title: 'Xe máy',
                icon: Icons.two_wheeler_rounded,
                isSelected: selectedOption == Transportation.motorbike,
                onTap: () => onChanged(Transportation.motorbike),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildItem({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.premiumBlue : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.premiumBlue : AppColors.premiumBorder,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.premiumBlue.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.premiumNavy,
              size: 30,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : AppColors.premiumNavy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
