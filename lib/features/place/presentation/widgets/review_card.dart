import 'package:flutter/material.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/core/widgets/net_image.dart';
import 'package:travel_advisor_mobile/features/place/domain/entities/place_review_entity.dart';

class ReviewCard extends StatelessWidget {
  final PlaceReviewEntity review;

  const ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: NetImage(
                  url: review.userAvatar,
                  width: 36,
                  height: 36,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _stars(review.rating),
                        const SizedBox(width: 8),
                        Text(
                          review.timeAgo,
                          style: const TextStyle(
                            fontSize: 11, 
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.reviewText,
            style: const TextStyle(
              fontSize: 13, 
              height: 1.4, 
              color: AppColors.textPrimary,
            ),
          ),
          if (review.reviewImages.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 60,
              child: ListView.separated(
                padding: EdgeInsets.zero,
                scrollDirection: Axis.horizontal,
                itemCount: review.reviewImages.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: NetImage(
                    url: review.reviewImages[index], 
                    width: 60, 
                    height: 60, 
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stars(double rating) {
    return Row(
      children: List.generate(5, (index) => Icon(
        Icons.star,
        size: 12,
        color: index < rating.floor() ? Colors.amber : Colors.grey.withValues(alpha: 0.3),
      )),
    );
  }
}