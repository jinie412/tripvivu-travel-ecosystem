import 'package:flutter/material.dart';

import 'review_media_list.dart';
import 'star_rating_input.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/core/widgets/net_image.dart';
import 'package:travel_advisor_mobile/features/review/domain/entities/itinerary_review_entity.dart';

class ReviewItineraryCard extends StatelessWidget {
  final ItineraryReviewEntity itinerary;
  final double rating;
  final ValueChanged<double> onRatingChanged;
  final bool applyToAll;
  final ValueChanged<bool> onApplyToAllChanged;
  final List<String> mediaPaths;
  final VoidCallback onAddMedia;
  final ValueChanged<String> onRemoveMedia;
  final VoidCallback onClearAllMedia;

  const ReviewItineraryCard({
    super.key,
    required this.itinerary,
    required this.rating,
    required this.onRatingChanged,
    required this.applyToAll,
    required this.onApplyToAllChanged,
    required this.mediaPaths,
    required this.onAddMedia,
    required this.onRemoveMedia,
    required this.onClearAllMedia,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tổng quan về lịch trình',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 12),
          // Itinerary Image Card
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                NetImage(
                  url: itinerary.imageUrl,
                  placeholderColor: AppColors.blobMedium.toARGB32(),
                ),
                Container(
                  color: Colors.black.withValues(alpha: 0.3),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          itinerary.status,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        itinerary.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        itinerary.dateRange,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Bạn có cảm nhận như thế nào?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 12),
          StarRatingInput(rating: rating, onRatingChanged: onRatingChanged),
          const SizedBox(height: 16),
          Row(
            children: [
              GestureDetector(
                onTap: () => onApplyToAllChanged(!applyToAll),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: applyToAll ? AppColors.primary : Colors.white,
                    border: applyToAll ? null : Border.all(color: Colors.grey.shade400),
                    shape: BoxShape.circle,
                  ),
                  child: applyToAll ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Áp dụng xếp hạng này cho tất cả các địa điểm',
                  style: TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
                ),
              )
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'ĐÁNH GIÁ CHUNG',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              maxLines: 4,
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                filled: false,
                hintText: 'Hãy cho chúng tôi biết về những điểm nổi bật, về vấn đề hậu cần và những gì có thể được cải thiện...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ReviewMediaList(
            mediaPaths: mediaPaths,
            onAddMedia: onAddMedia,
            onRemoveMedia: onRemoveMedia,
            onClearAllMedia: onClearAllMedia,
          ),
        ],
      ),
    );
  }
}