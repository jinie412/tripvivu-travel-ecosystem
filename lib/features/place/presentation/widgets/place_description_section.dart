import 'package:flutter/material.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';

class PlaceDescriptionSection extends StatelessWidget {
  final String description;

  const PlaceDescriptionSection({super.key, required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mô tả',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.5,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}