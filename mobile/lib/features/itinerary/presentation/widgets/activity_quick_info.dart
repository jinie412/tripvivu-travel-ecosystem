import 'package:flutter/material.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';

class ActivityQuickInfo extends StatelessWidget {
  final String opening;
  final String price;
  final double rating;
  final int reviews;

  const ActivityQuickInfo({
    super.key,
    required this.opening,
    required this.price,
    required this.rating,
    required this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _infoBox(Icons.access_time, 'MỞ CỬA', opening),
        const SizedBox(width: 12),
        _infoBox(Icons.local_offer_outlined, 'GIÁ VÉ', price),
        const SizedBox(width: 12),
        _infoBox(Icons.star_outline, 'ĐÁNH GIÁ', '$rating (${(reviews/1000).toStringAsFixed(1)}k)'),
      ],
    );
  }

  Widget _infoBox(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9), // Very light gray/blue
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              label, 
              style: const TextStyle(
                fontSize: 9, 
                color: AppColors.textSecondary, 
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value, 
              style: const TextStyle(
                fontSize: 11, 
                fontWeight: FontWeight.bold, 
                color: Color(0xFF1E293B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}