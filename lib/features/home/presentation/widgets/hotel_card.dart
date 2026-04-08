import 'package:flutter/material.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/core/widgets/net_image.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/hotel.dart';

class HotelCard extends StatelessWidget {
  final Hotel item;

  const HotelCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          height: 120,
          child: NetImage(
              url: item.imageUrl, placeholderColor: item.placeholderColor),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              item.name,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C1C1E)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFA500)),
              const SizedBox(width: 2),
              Text(
                item.rating.toString(),
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF1C1C1E),
                    fontWeight: FontWeight.w600),
              ),
            ]),
            const SizedBox(height: 4),
            Text(
              item.price,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary),
            ),
            Text(
              item.priceUnit,
              style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
            ),
          ]),
        ),
      ]),
    );
  }
}