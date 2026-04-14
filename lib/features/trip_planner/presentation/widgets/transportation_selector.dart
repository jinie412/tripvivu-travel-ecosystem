import 'package:flutter/material.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/features/trip_planner/domain/entities/trip_form.dart';

class TransportationSelector extends StatelessWidget {
  final Transportation selectedOption;
  final ValueChanged<Transportation> onChanged;
  final TripType selectedType;
  final ValueChanged<TripType> onTypeChanged;

  const TransportationSelector({
    super.key,
    required this.selectedOption,
    required this.onChanged,
    required this.selectedType,
    required this.onTypeChanged,
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
        const SizedBox(height: 16),
        // Thanh chọn Khứ hồi / Một chiều được lồng vào bên trong
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Expanded(
                child: _buildTypeOption(
                  title: 'Khứ hồi',
                  isSelected: selectedType == TripType.roundTrip,
                  onTap: () => onTypeChanged(TripType.roundTrip),
                ),
              ),
              Expanded(
                child: _buildTypeOption(
                  title: 'Một chiều',
                  isSelected: selectedType == TripType.oneWay,
                  onTap: () => onTypeChanged(TripType.oneWay),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeOption({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
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
            color: isSelected ? AppColors.primary : AppColors.inputBorder.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
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