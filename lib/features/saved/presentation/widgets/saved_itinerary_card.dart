import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../city_detail/domain/entities/city_entities.dart';

class SavedItineraryCard extends StatelessWidget {
  final CityItinerary item;
  final VoidCallback? onTap;

  const SavedItineraryCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CachedNetworkImage(
            imageUrl: item.imageUrl,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: Colors.grey[200]),
            errorWidget: (context, url, error) => const Icon(Icons.error),
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
          ),
        ),
        const SizedBox(height: 10),
        // Single Metadata Row: Author, Location, Views, Likes
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 12,
              backgroundImage: CachedNetworkImageProvider(
                item.authorAvatar,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                item.authorName,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
            const Spacer(),
            const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                item.location,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.visibility_outlined, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                item.views,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.favorite, size: 12, color: Colors.redAccent),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                item.likes,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ],
    ),
    );
  }
}
