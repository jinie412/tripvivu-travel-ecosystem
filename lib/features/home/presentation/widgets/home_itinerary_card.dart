import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/core/widgets/default_avatar.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/trip_suggestion.dart';

class HomeItineraryCard extends StatelessWidget {
  final TripSuggestion item;
  final ValueChanged<bool>? onFavoriteChanged;

  const HomeItineraryCard({
    super.key,
    required this.item,
    this.onFavoriteChanged,
  });

  static const double _radius = 12;

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
              _buildItineraryImageGallery(),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
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
            DefaultAvatar(
              radius: 12,
              imageUrl: item.authorAvatar,
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
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 12,
              color: Colors.grey,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                item.location,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (item.rating > 0) ...[
              const SizedBox(width: 8),
              const Icon(Icons.star_rounded, size: 13, color: Color(0xFFFFB400)),
              const SizedBox(width: 3),
              Text(
                item.rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
            const SizedBox(width: 8),
            const Icon(Icons.favorite, size: 12, color: Colors.redAccent),
            const SizedBox(width: 4),
            Text(
              item.likes,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildItineraryImageGallery() {
    final gallery = item.imageUrls
        .where((url) => url.trim().isNotEmpty)
        .where((url) => !_isUnsafeUrl(url))
        .take(3)
        .toList();

    if (gallery.isEmpty &&
        item.imageUrl != null &&
        item.imageUrl!.trim().isNotEmpty &&
        !_isUnsafeUrl(item.imageUrl!)) {
      gallery.add(item.imageUrl!.trim());
    }

    if (gallery.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: _assetPlaceholder(),
      );
    }

    if (gallery.length == 1) {
      return _galleryImage(gallery.first, BorderRadius.circular(_radius));
    }

    const r = Radius.circular(_radius);
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _galleryImage(
            gallery[0],
            const BorderRadius.only(topLeft: r, bottomLeft: r),
          ),
        ),
        const SizedBox(width: 3),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: _galleryImage(
                  gallery[1],
                  const BorderRadius.only(topRight: r),
                ),
              ),
              const SizedBox(height: 3),
              Expanded(
                child: gallery.length >= 3
                    ? _galleryImage(
                        gallery[2],
                        const BorderRadius.only(bottomRight: r),
                      )
                    : ClipRRect(
                        borderRadius: const BorderRadius.only(bottomRight: r),
                        child: _assetPlaceholder(),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _galleryImage(String imageUrl, BorderRadius borderRadius) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorWidget: (context, url, error) => _assetPlaceholder(),
      ),
    );
  }

  Widget _assetPlaceholder() {
    return Transform.scale(
      scale: 1.1,
      child: Image.asset(
        'assets/images/itinerary_placeholder.png',
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }

  bool _isUnsafeUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return true;
    final host = uri.host.toLowerCase();
    return host == 'tinyurl.vn' || host == 'down-vn.img.susercontent.com';
  }
}
