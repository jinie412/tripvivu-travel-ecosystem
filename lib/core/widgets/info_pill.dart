import 'package:flutter/material.dart';
import 'package:travel_advisor_mobile/core/theme/app_colors.dart';

enum InfoPillVariant { dark, light }

/// Small rounded badge (icon + short label). `dark` sits on a photo/scrim
/// (semi-transparent black, white text); `light` sits on the flat body
/// background (soft blue tint, navy text).
class InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final InfoPillVariant variant;

  const InfoPill({
    super.key,
    required this.icon,
    required this.label,
    this.variant = InfoPillVariant.light,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = variant == InfoPillVariant.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.35)
            : AppColors.premiumSoftBlue,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.15)
              : AppColors.premiumBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isDark
                ? Colors.white.withValues(alpha: 0.9)
                : AppColors.premiumBlue,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.95)
                    : AppColors.premiumNavy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
