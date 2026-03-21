import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class MemberCounterCard extends StatelessWidget {
  final int adultCount;
  final int childCount;
  final VoidCallback onAdultIncrease;
  final VoidCallback onAdultDecrease;
  final VoidCallback onChildIncrease;
  final VoidCallback onChildDecrease;

  const MemberCounterCard({
    super.key,
    required this.adultCount,
    required this.childCount,
    required this.onAdultIncrease,
    required this.onAdultDecrease,
    required this.onChildIncrease,
    required this.onChildDecrease,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildCounter(
            title: 'NGƯỜI LỚN',
            count: adultCount,
            onIncrease: onAdultIncrease,
            onDecrease: onAdultDecrease,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildCounter(
            title: 'TRẺ EM',
            count: childCount,
            onIncrease: onChildIncrease,
            onDecrease: onChildDecrease,
          ),
        ),
      ],
    );
  }

  Widget _buildCounter({
    required String title,
    required int count,
    required VoidCallback onIncrease,
    required VoidCallback onDecrease,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildControlButton(
                icon: Icons.remove,
                onTap: onDecrease,
                isEnabled: count > 0, // In Cubit, adultCount stops at 1
              ),
              Text(
                count.toString(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              _buildControlButton(
                icon: Icons.add,
                onTap: onIncrease,
                isEnabled: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isEnabled,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isEnabled ? AppColors.inputFill : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: isEnabled ? AppColors.primary : AppColors.inputBorder,
        ),
      ),
    );
  }
}
