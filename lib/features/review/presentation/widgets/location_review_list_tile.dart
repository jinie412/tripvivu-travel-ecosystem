import 'dart:io';

import 'package:flutter/material.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/core/widgets/net_image.dart';
import 'package:travel_advisor_mobile/features/review/domain/entities/location_review_entity.dart';
import 'package:travel_advisor_mobile/features/review/domain/entities/review_media_item.dart';

class LocationReviewListTile extends StatefulWidget {
  final LocationReviewEntity location;
  final bool isVisited;
  final ValueChanged<double>? onRatingChanged;
  final VoidCallback? onWriteReview;
  final bool isReadOnly;
  final List<ReviewMediaItem> mediaItems;

  const LocationReviewListTile({
    super.key,
    required this.location,
    this.isVisited = true,
    this.onRatingChanged,
    this.onWriteReview,
    this.isReadOnly = false,
    this.mediaItems = const [],
  });

  @override
  State<LocationReviewListTile> createState() => _LocationReviewListTileState();
}

class _LocationReviewListTileState extends State<LocationReviewListTile> {
  @override
  Widget build(BuildContext context) {
    final bool isVisited = widget.isVisited;

    return Opacity(
      opacity: isVisited ? 1.0 : 0.6,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: NetImage(
                url: widget.location.imageUrl,
                placeholderColor: AppColors.blobLight.toARGB32(),
              ),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.blobLight.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'NGÀY ${widget.location.day}',
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      Row(
                        children: List.generate(5, (index) {
                          final starValue = index + 1;
                          return GestureDetector(
                            onTap:
                                (isVisited &&
                                    !widget.isReadOnly &&
                                    widget.onRatingChanged != null)
                                ? () => widget.onRatingChanged!(
                                    starValue.toDouble(),
                                  )
                                : null,
                            child: Icon(
                              starValue <= (widget.location.rating ?? 0)
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              size: 14,
                              color: isVisited
                                  ? const Color(0xFFFFB020)
                                  : const Color(0xFF94A3B8),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.location.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),

                  if (!isVisited)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'Bạn chưa đi địa điểm này nên ko được đánh giá',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFFEF4444),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),

                  const SizedBox(height: 6),
                  if (widget.location.reviewText != null &&
                      widget.location.reviewText!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        widget.location.reviewText!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  if (widget.mediaItems.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 52,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.mediaItems.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          return _LocationMediaThumb(
                            item: widget.mediaItems[index],
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: isVisited ? widget.onWriteReview : null,
                      child: Text(
                        widget.isReadOnly
                            ? 'Xem đầy đủ đánh giá'
                            : 'Viết đánh giá',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isVisited
                              ? AppColors.primary.withValues(alpha: 0.8)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationMediaThumb extends StatelessWidget {
  final ReviewMediaItem item;

  const _LocationMediaThumb({required this.item});

  bool get _isBusy {
    return item.status == ReviewMediaUploadStatus.compressing;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        children: [
          Container(
            width: 52,
            height: 52,
            color: const Color(0xFFF3F4F6),
            child: item.type == ReviewMediaType.image
                ? (item.remoteUrl != null
                      ? Image.network(
                          item.remoteUrl!,
                          fit: BoxFit.cover,
                          cacheWidth: 156, // thumbnail 52dp — không giải mã full-res
                          errorBuilder: (context, error, stack) => const Icon(
                            Icons.broken_image_outlined,
                            size: 24,
                            color: Color(0xFF94A3B8),
                          ),
                        )
                      : Image.file(File(item.localPath), fit: BoxFit.cover))
                : const ColoredBox(
                    color: Color(0xFF111827),
                    child: Center(
                      child: Icon(
                        Icons.play_circle_fill_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
          ),
          if (_isBusy)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.68),
                padding: const EdgeInsets.all(6),
                child: const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
