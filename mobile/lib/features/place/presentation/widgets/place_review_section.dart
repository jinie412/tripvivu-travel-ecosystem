import 'package:flutter/material.dart';

import 'review_card.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/features/place/domain/entities/place_review_entity.dart';

class PlaceReviewSection extends StatelessWidget {
  final double rating;
  final int totalReviews;
  final List<PlaceReviewEntity> reviews;
  final Map<int, int>? breakdown;
  final VoidCallback? onViewAll;

  const PlaceReviewSection({
    super.key,
    required this.rating,
    required this.totalReviews,
    required this.reviews,
    this.breakdown,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBreakdown = breakdown ?? _buildBreakdown(reviews);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bài đánh giá',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.premiumNavy,
                ),
              ),
              if (onViewAll != null)
                TextButton(
                  onPressed: onViewAll,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Xem tất cả',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _ratingSummaryBox(totalReviews, effectiveBreakdown),
          if (reviews.isNotEmpty) ...[
            const SizedBox(height: 24),
            ...reviews.take(3).map((review) => ReviewCard(review: review)),
          ],
        ],
      ),
    );
  }

  Map<int, int> _buildBreakdown(List<PlaceReviewEntity> items) {
    final map = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final item in items) {
      final star = item.rating.round().clamp(1, 5);
      map[star] = (map[star] ?? 0) + 1;
    }
    return map;
  }

  double _toPercent(int count, int total) {
    if (total <= 0) {
      return 0;
    }
    return count / total;
  }

  Widget _ratingSummaryBox(int reviewCount, Map<int, int> breakdown) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.premiumSoftBlue,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.premiumBorder),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        _formatRating(rating),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Text(
                        '/5',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _stars(rating),
                const SizedBox(height: 8),
                Text(
                  '$reviewCount đánh giá',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: [
                _ratingBar(5, _toPercent(breakdown[5] ?? 0, reviewCount)),
                _ratingBar(4, _toPercent(breakdown[4] ?? 0, reviewCount)),
                _ratingBar(3, _toPercent(breakdown[3] ?? 0, reviewCount)),
                _ratingBar(2, _toPercent(breakdown[2] ?? 0, reviewCount)),
                _ratingBar(1, _toPercent(breakdown[1] ?? 0, reviewCount)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ratingBar(int star, double percent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          Text(
            star.toString(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: percent,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
                minHeight: 5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stars(double rating) {
    final roundedRating = (rating * 10).round() / 10;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        5,
        (index) =>
            _fractionalStar((roundedRating - index).clamp(0.0, 1.0).toDouble()),
      ),
    );
  }

  Widget _fractionalStar(double fill) {
    const size = 16.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Icon(
            Icons.star,
            size: size,
            color: Colors.grey.withValues(alpha: 0.3),
          ),
          ClipRect(
            clipper: _StarFillClipper(fill),
            child: const Icon(Icons.star, size: size, color: Colors.amber),
          ),
        ],
      ),
    );
  }

  String _formatRating(double value) {
    if (value <= 0) {
      return '0';
    }
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }
}

class _StarFillClipper extends CustomClipper<Rect> {
  final double fill;

  const _StarFillClipper(this.fill);

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * fill, size.height);

  @override
  bool shouldReclip(_StarFillClipper oldClipper) => oldClipper.fill != fill;
}
