import 'package:flutter/material.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/core/widgets/net_image.dart';
import 'package:travel_advisor_mobile/features/place/domain/entities/place_entity.dart';

class RelatedPlacesSection extends StatelessWidget {
  final List<PlaceEntity> relatedPlaces;

  const RelatedPlacesSection({super.key, required this.relatedPlaces});

  @override
  Widget build(BuildContext context) {
    if (relatedPlaces.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Các địa điểm liên quan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 170,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: relatedPlaces.length,
              separatorBuilder: (context, index) => const SizedBox(width: 14),
              itemBuilder: (context, index) => _placeCard(relatedPlaces[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeCard(PlaceEntity place) {
    return Container(
      width: 170,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: NetImage(
              url: place.imageUrl, 
              height: 100, 
              width: double.infinity, 
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star, size: 10, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      place.rating.toString(), 
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      place.district, 
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}