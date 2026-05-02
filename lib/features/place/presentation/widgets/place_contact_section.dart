import 'package:flutter/material.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';

class PlaceContactSection extends StatelessWidget {
  final String openingTime;
  final String closingTime;
  final String phone;
  final String address;
  final VoidCallback? onLocationTap;

  const PlaceContactSection({
    super.key,
    required this.openingTime,
    required this.closingTime,
    required this.phone,
    required this.address,
    this.onLocationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          _contactItem(
            Icons.access_time, 
            'Mở cửa $openingTime - Đóng cửa $closingTime',
            const Color(0xFF0EA5E9),
          ),
          const SizedBox(height: 12),
          _contactItem(
            Icons.phone_outlined, 
            phone,
            const Color(0xFF10B981),
          ),
          const SizedBox(height: 12),
          _contactItem(
            Icons.location_on_outlined, 
            address,
            const Color(0xFFF43F5E),
            onTap: onLocationTap,
            isLink: true,
          ),
        ],
      ),
    );
  }

  Widget _contactItem(IconData icon, String text, Color iconColor, {VoidCallback? onTap, bool isLink = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14, 
                  color: isLink ? const Color(0xFF2563EB) : AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  decoration: isLink ? TextDecoration.underline : null,
                  decorationColor: const Color(0xFF2563EB).withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}