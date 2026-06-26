import 'package:flutter/material.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';

class PlaceInfoSection extends StatelessWidget {
  final String name;
  final double rating;
  final String location;
  final List<String> vibes;
  final VoidCallback? onLocationTap;

  const PlaceInfoSection({
    super.key,
    required this.name,
    required this.rating,
    required this.location,
    required this.vibes,
    this.onLocationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 22, 
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _ratingBadge(rating),
            ],
          ),
          const SizedBox(height: 16),
          if (vibes.isNotEmpty)
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: vibes.map((vibe) => _vibeWidget(vibe)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _ratingBadge(double rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            rating.toString(),
            style: const TextStyle(
              color: Colors.white, 
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const Icon(Icons.star, color: Colors.amber, size: 12),
        ],
      ),
    );
  }

  Widget _vibeWidget(String vibe) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0F2FE)),
      ),
      child: Text(
        vibe,
        style: const TextStyle(
          color: Color(0xFF0369A1), 
          fontSize: 11, 
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}