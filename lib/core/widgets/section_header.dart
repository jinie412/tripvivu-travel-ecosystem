import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback? onSeeAll;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel = 'Xem tất cả',
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C1C1E),
            ),
          ),
          if (onSeeAll != null && actionLabel.isNotEmpty)
            GestureDetector(
              onTap: onSeeAll,
              child: Text(
                actionLabel,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
