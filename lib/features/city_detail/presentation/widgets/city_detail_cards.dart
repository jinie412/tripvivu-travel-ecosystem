import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/features/city_detail/domain/entities/city_entities.dart';

class LikeButton extends StatefulWidget {
  final double size;
  const LikeButton({super.key, this.size = 20});

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> {
  bool _isLiked = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _isLiked = !_isLiked),
      child: CircleAvatar(
        radius: widget.size * 0.9,
        backgroundColor: Colors.white,
        child: Icon(
          _isLiked ? Icons.favorite : Icons.favorite_border,
          color: _isLiked ? Colors.red : Colors.grey,
          size: widget.size,
        ),
      ),
    );
  }
}

class ItineraryCard extends StatelessWidget {
  final CityItinerary item;
  const ItineraryCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: item.imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
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
                  item.duration,
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
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 12,
              backgroundImage: CachedNetworkImageProvider(item.authorAvatar),
            ),
            const SizedBox(width: 8),
            Text(
              item.authorName,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const Spacer(),
            const Icon(Icons.visibility_outlined, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(item.views, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.favorite, size: 12, color: Colors.redAccent),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(item.likes, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ],
    );
  }
}

class ActivityCard extends StatelessWidget {
  final CityActivity item;
  const ActivityCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: item.imageUrl,
                height: 112,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const Positioned(
              top: 8,
              right: 8,
              child: LikeButton(size: 16),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: Text(
            item.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class RestaurantCard extends StatelessWidget {
  final CityRestaurant item;
  const RestaurantCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: item.imageUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const Positioned(
              top: 8,
              right: 8,
              child: LikeButton(size: 16),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 14),
            const SizedBox(width: 2),
            Text(
              item.rating.toString(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '(${item.reviewCount} đánh giá)',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class HotelCard extends StatelessWidget {
  final CityHotel item;
  const HotelCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: item.imageUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const Positioned(
              top: 8,
              right: 8,
              child: LikeButton(size: 16),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 14),
            const SizedBox(width: 2),
            Text(
              item.rating.toString(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '(${item.reviewCount} đánh giá)',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.black, fontSize: 13),
            children: [
              TextSpan(
                text: item.price,
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              TextSpan(
                text: ' / đêm',
                style: TextStyle(color: Colors.grey[600], fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class Position extends StatelessWidget {
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final Widget child;

  const Position({
    super.key,
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: child,
    );
  }
}