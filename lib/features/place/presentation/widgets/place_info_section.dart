import 'package:flutter/material.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';

class PlaceInfoSection extends StatelessWidget {
  final String name;
  final double rating;
  final List<String> vibes;
  final double? minimumHotelPrice;

  const PlaceInfoSection({
    super.key,
    required this.name,
    required this.rating,
    required this.vibes,
    this.minimumHotelPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.premiumSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.premiumBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.premiumNavy,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _ratingBadge(rating),
            ],
          ),
          if (minimumHotelPrice != null && minimumHotelPrice! > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.payments_outlined,
                  size: 18,
                  color: AppColors.premiumBlue,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    'Từ ${_formatPrice(minimumHotelPrice!)}/đêm',
                    style: const TextStyle(
                      color: AppColors.premiumBlue,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (vibes.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: vibes.map((vibe) => _vibeWidget(vibe)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _ratingBadge(double rating) {
    return Container(
      constraints: const BoxConstraints(minWidth: 48),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.premiumBlue, AppColors.premiumTeal],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatRating(rating),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 1),
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

  String _formatRating(double value) {
    return value.toStringAsFixed(1);
  }

  String _formatPrice(double value) {
    final digits = value.round().toString();
    return '${digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    )}đ';
  }
}
