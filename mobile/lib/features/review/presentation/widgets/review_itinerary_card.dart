import 'package:flutter/material.dart';

import 'review_media_list.dart';
import 'star_rating_input.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/core/widgets/net_image.dart';
import 'package:travel_advisor_mobile/features/review/presentation/constants/review_tags.dart';
import 'package:travel_advisor_mobile/features/review/domain/entities/itinerary_review_entity.dart';
import 'package:travel_advisor_mobile/features/review/domain/entities/review_media_item.dart';

class ReviewItineraryCard extends StatelessWidget {
  final ItineraryReviewEntity itinerary;
  final double rating;
  final ValueChanged<double> onRatingChanged;
  final bool applyToAll;
  final ValueChanged<bool> onApplyToAllChanged;
  final String generalComment;
  final ValueChanged<String> onGeneralCommentChanged;
  final List<String> selectedTags;
  final ValueChanged<String> onTagToggled;
  final List<ReviewMediaItem> mediaItems;
  final VoidCallback onAddImages;
  final VoidCallback onAddVideo;
  final ValueChanged<String> onRemoveMedia;
  final VoidCallback onClearAllMedia;
  final bool isReadOnly;

  const ReviewItineraryCard({
    super.key,
    required this.itinerary,
    required this.rating,
    required this.onRatingChanged,
    required this.applyToAll,
    required this.onApplyToAllChanged,
    required this.generalComment,
    required this.onGeneralCommentChanged,
    required this.selectedTags,
    required this.onTagToggled,
    required this.mediaItems,
    required this.onAddImages,
    required this.onAddVideo,
    required this.onRemoveMedia,
    required this.onClearAllMedia,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayStatus = switch (itinerary.status.toLowerCase()) {
      'completed' => 'HOÀN THÀNH',
      'ongoing' => 'ĐANG DIỄN RA',
      'upcoming' => 'SẮP DIỄN RA',
      final v when v.isNotEmpty => v.toUpperCase(),
      _ => itinerary.status,
    };
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
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                (itinerary.imageUrl.isNotEmpty)
                    ? NetImage(
                        url: itinerary.imageUrl,
                        placeholderColor: AppColors.blobMedium.toARGB32(),
                      )
                    : Transform.scale(
                        scale: 1.1,
                        child: Image.asset(
                          'assets/images/itinerary_placeholder.png',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                Container(color: Colors.black.withValues(alpha: 0.3)),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          displayStatus,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
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
                ),
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
          StarRatingInput(
            rating: rating,
            onRatingChanged: onRatingChanged,
            mainAxisAlignment: MainAxisAlignment.center,
            enabled: !isReadOnly,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              GestureDetector(
                onTap: isReadOnly
                    ? null
                    : () => onApplyToAllChanged(!applyToAll),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: applyToAll ? AppColors.primary : Colors.white,
                    border: applyToAll
                        ? null
                        : Border.all(color: Colors.grey.shade400),
                    shape: BoxShape.circle,
                  ),
                  child: applyToAll
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Áp dụng xếp hạng này cho tất cả các địa điểm',
                  style: TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'ĐÁNH GIÁ LỊCH TRÌNH',
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
            child: TextFormField(
              maxLines: 4,
              initialValue: generalComment,
              readOnly: isReadOnly,
              onChanged: isReadOnly ? null : onGeneralCommentChanged,
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                filled: false,
                hintText:
                    'Hãy cho chúng tôi biết về những điểm nổi bật, về vấn đề hậu cần và những gì có thể được cải thiện...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          if (!isReadOnly || selectedTags.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              isReadOnly ? 'Từ khóa đánh giá' : 'Gợi ý nhanh',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (isReadOnly ? selectedTags : kItineraryReviewTags).map((
                tag,
              ) {
                final isSelected = selectedTags.contains(tag);
                return GestureDetector(
                  onTap: isReadOnly ? null : () => onTagToggled(tag),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.blobLight
                          : const Color(0xFFF0FDF4).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? AppColors.primary
                            : const Color(0xFF0D9488),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 20),
          ReviewMediaList(
            mediaItems: mediaItems,
            onAddImages: onAddImages,
            onAddVideo: onAddVideo,
            onRemoveMedia: onRemoveMedia,
            onClearAllMedia: onClearAllMedia,
            isReadOnly: isReadOnly,
          ),
        ],
      ),
    );
  }
}
