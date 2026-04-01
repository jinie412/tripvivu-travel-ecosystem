import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/features/city_detail/presentation/widgets/city_detail_cards.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/trip_suggestion.dart';

class HomeItineraryCard extends StatelessWidget {
  final TripSuggestion item;
  const HomeItineraryCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: item.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: item.imageUrl!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 180,
                      width: double.infinity,
                      color: Color(item.placeholderColor),
                      child: const Icon(Icons.image, color: Colors.white, size: 40),
                    ),
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
            const Positioned(
              top: 12,
              right: 12,
              child: LikeButton(),
            ),
          ],
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
                'https://i.pravatar.cc/100?u=${item.id}',
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                'Traveler',
                style: TextStyle(fontSize: 11, color: Colors.grey),
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
    );
  }
}