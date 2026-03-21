import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class TopicSelector extends StatelessWidget {
  final String? selectedTopic;
  final VoidCallback onTap;

  const TopicSelector({
    Key? key,
    this.selectedTopic,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.inputBorder.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.explore_outlined, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedTopic ?? 'Khám phá & Trải nghiệm',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
