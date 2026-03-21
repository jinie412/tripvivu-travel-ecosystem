import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/trip_form.dart';

class TripTypeSelector extends StatelessWidget {
  final TripType selectedType;
  final ValueChanged<TripType> onChanged;

  const TripTypeSelector({
    Key? key,
    required this.selectedType,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputBorder.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _buildOption(
              context: context,
              title: 'Khứ hồi',
              isSelected: selectedType == TripType.roundTrip,
              onTap: () => onChanged(TripType.roundTrip),
            ),
          ),
          Expanded(
            child: _buildOption(
              context: context,
              title: 'Một chiều',
              isSelected: selectedType == TripType.oneWay,
              onTap: () => onChanged(TripType.oneWay),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
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
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
