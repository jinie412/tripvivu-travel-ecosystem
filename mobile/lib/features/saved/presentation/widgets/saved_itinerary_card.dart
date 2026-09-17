import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/features/saved/domain/entities/favorite_itinerary_entity.dart';

class SavedItineraryCard extends StatelessWidget {
  final FavoriteItineraryEntity item;
  final VoidCallback? onTap;

  const SavedItineraryCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.premiumBorder),
          boxShadow: [
            BoxShadow(
              color: AppColors.premiumNavy.withValues(alpha: .08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildItineraryImageGallery(),
            ),
            const SizedBox(height: 12),
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            // Metadata Row: Location, Days, Status
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 12,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      item.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '${item.days} ngày',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFB547)),
                const SizedBox(width: 4),
                Text(
                  item.rating > 0 ? item.rating.toStringAsFixed(1) : 'Chưa có',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.premiumMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItineraryImageGallery() {
    final gallery = item.imageGallery
        .where((url) => url.trim().isNotEmpty)
        .take(3)
        .toList();

    if (gallery.isEmpty && (item.image ?? '').trim().isNotEmpty) {
      gallery.add(item.image!.trim());
    }

    if (gallery.isEmpty) {
      return Container(
        height: 180,
        width: double.infinity,
        color: Colors.grey[200],
        alignment: Alignment.center,
        child: const Icon(Icons.image, color: Colors.grey, size: 40),
      );
    }

    if (gallery.length == 1) {
      return _buildNetworkImage(gallery.first, height: 180);
    }

    return SizedBox(
      height: 180,
      child: Row(
        children: [
          Expanded(flex: 2, child: _buildNetworkImage(gallery[0], height: 180)),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _buildNetworkImage(
                    gallery[1],
                    height: double.infinity,
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: gallery.length >= 3
                      ? _buildNetworkImage(gallery[2], height: double.infinity)
                      : Container(color: Colors.grey[300]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkImage(String imageUrl, {required double height}) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      memCacheWidth: 1080, // ảnh card — không giải mã full-res
      placeholder: (context, url) => Container(color: Colors.grey[200]),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[300],
        child: const Icon(Icons.broken_image),
      ),
    );
  }
}
