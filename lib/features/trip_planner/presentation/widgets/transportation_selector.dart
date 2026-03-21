import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/trip_form.dart';

class TransportationSelector extends StatelessWidget {
  final Transportation selectedOption;
  final ValueChanged<Transportation> onChanged;

  const TransportationSelector({
    Key? key,
    required this.selectedOption,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phương tiện di chuyển',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildItem(
                context,
                title: 'MÁY BAY',
                icon: Icons.flight_takeoff_outlined,
                isSelected: selectedOption == Transportation.flights,
                onTap: () => onChanged(Transportation.flights),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildItem(
                context,
                title: 'ĐƯỜNG BỘ',
                icon: Icons.directions_car_outlined,
                isSelected: selectedOption == Transportation.road,
                onTap: () => onChanged(Transportation.road),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildItem(
                context,
                title: 'ĐƯỜNG THỦY',
                icon: Icons.directions_boat_outlined,
                isSelected: selectedOption == Transportation.water,
                onTap: () => onChanged(Transportation.water),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.inputBorder.withOpacity(0.5),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    spreadRadius: 0,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.textPrimary,
              size: 28,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
