import 'package:flutter/material.dart';
import '../../domain/entities/place_review_entity.dart';
import '../../../../core/theme/app_colors.dart';
import 'review_card.dart';

class PlaceReviewSection extends StatelessWidget {
  final double rating;
  final int totalReviews;
  final List<PlaceReviewEntity> reviews;

  const PlaceReviewSection({
    super.key,
    required this.rating,
    required this.totalReviews,
    required this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bài đánh giá',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Xem tất cả', 
                  style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ratingSummaryBox(),
          const SizedBox(height: 24),
          ...reviews.asMap().entries.map((entry) => ReviewCard(
            review: entry.value,
          )),
        ],
      ),
    );
  }

  Widget _ratingSummaryBox() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    rating.toString(),
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Text(
                      '/5', 
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              _stars(rating.floor()),
              const SizedBox(height: 8),
              Text(
                '$totalReviews đánh giá',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              children: [
                _ratingBar(5, 0.8),
                _ratingBar(4, 0.4),
                _ratingBar(3, 0.2),
                _ratingBar(2, 0.1),
                _ratingBar(1, 0.05),
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
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: percent,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stars(int count) {
    return Row(
      children: List.generate(5, (index) => Icon(
        Icons.star,
        size: 16,
        color: index < count ? Colors.amber : Colors.grey.withValues(alpha: 0.3),
      )),
    );
  }
}
