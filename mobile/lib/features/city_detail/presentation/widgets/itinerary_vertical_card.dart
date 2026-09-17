import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/core/widgets/default_avatar.dart';
import 'package:travel_advisor_mobile/features/city_detail/domain/entities/city_entities.dart';

class ItineraryVerticalCard extends StatelessWidget {
  final CityItinerary item;
  const ItineraryVerticalCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.premiumSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.premiumBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.premiumNavy.withValues(alpha: .08),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 132,
          child: Row(
            children: [
              SizedBox(
                width: 124,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: item.imageUrl,
                      fit: BoxFit.cover,
                      memCacheWidth: 372,
                      placeholder: (_, _) =>
                          Container(color: AppColors.premiumSoftBlue),
                      errorWidget: (_, _, _) => Container(
                        color: AppColors.premiumSoftBlue,
                        child: const Icon(
                          Icons.map_outlined,
                          color: AppColors.premiumBlue,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .94),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          item.duration.toLowerCase(),
                          style: const TextStyle(
                            color: AppColors.premiumNavy,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.premiumNavy,
                          fontSize: 15,
                          height: 1.22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          DefaultAvatar(
                            radius: 11,
                            imageUrl: item.authorAvatar,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              item.authorName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.premiumMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 13,
                            color: AppColors.premiumBlue,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.location.isNotEmpty
                                  ? item.location
                                  : 'Việt Nam',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.premiumMuted,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.favorite_rounded,
                            size: 12,
                            color: Color(0xFFFF6B6B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.likes,
                            style: const TextStyle(
                              color: AppColors.premiumMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
