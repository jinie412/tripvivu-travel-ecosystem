import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class PlaceContactSection extends StatelessWidget {
  final String openingTime;
  final String closingTime;
  final String phone;
  final String address;

  const PlaceContactSection({
    super.key,
    required this.openingTime,
    required this.closingTime,
    required this.phone,
    required this.address,
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
          ),
        ],
      ),
    );
  }

  Widget _contactItem(IconData icon, String text, Color iconColor) {
    return Container(
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
              style: const TextStyle(
                fontSize: 14, 
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
