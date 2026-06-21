import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/features/city_detail/presentation/widgets/city_detail_cards.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/trip_suggestion.dart';

class HomeItineraryCard extends StatelessWidget {
  final TripSuggestion item;
  final ValueChanged<bool>? onFavoriteChanged;

  const HomeItineraryCard({
    super.key,
    required this.item,
    this.onFavoriteChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildItineraryImageGallery(),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.days.toLowerCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: LikeButton(
                  isLiked: item.isFavorite,
                  onChanged: onFavoriteChanged,
                ),
              ),
            ],
          ),
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
            height: 1.3,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 12,
              backgroundImage: CachedNetworkImageProvider(
                item.authorAvatar.isNotEmpty
                    ? item.authorAvatar
                    : 'https://i.pravatar.cc/100?u=${item.id}',
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                item.authorName,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Spacer(),
            const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                item.location,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.visibility_outlined, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Text(item.views, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(width: 8),
            const Icon(Icons.favorite, size: 12, color: Colors.redAccent),
            const SizedBox(width: 4),
            Text(item.likes, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(width: 4),
          ],
        ),
      ],
    );
  }

  Widget _buildItineraryImageGallery() {
    final gallery = item.imageUrls.where((url) => url.trim().isNotEmpty).take(3).toList();

    if (gallery.isEmpty && item.imageUrl != null && item.imageUrl!.trim().isNotEmpty) {
      gallery.add(item.imageUrl!.trim());
    }

    if (gallery.isEmpty) {
      return Container(
        color: Color(item.placeholderColor),
        alignment: Alignment.center,
        child: const Icon(Icons.image, color: Colors.white, size: 40),
      );
    }

    if (gallery.length == 1) {
      return _buildNetworkImage(gallery.first);
    }

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildNetworkImage(gallery[0]),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            children: [
              Expanded(child: _buildNetworkImage(gallery[1])),
              const SizedBox(height: 4),
              Expanded(
                child: gallery.length >= 3
                    ? _buildNetworkImage(gallery[2])
                    : Container(
                        color: Color(item.placeholderColor).withValues(alpha: 0.35),
                        child: const Icon(Icons.landscape, color: Colors.white54),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNetworkImage(String imageUrl) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: double.infinity,
      fit: BoxFit.cover,
      errorWidget: (context, url, error) => Container(
        color: Color(item.placeholderColor).withValues(alpha: 0.75),
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image, color: Colors.white),
      ),
    );
  }
}
