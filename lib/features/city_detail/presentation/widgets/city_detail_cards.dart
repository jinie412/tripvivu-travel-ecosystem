import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/core/widgets/default_avatar.dart';
import 'package:travel_advisor_mobile/features/city_detail/domain/entities/city_entities.dart';

class LikeButton extends StatefulWidget {
  final double size;
  final bool isLiked;
  final ValueChanged<bool>? onChanged;

  const LikeButton({
    super.key,
    this.size = 20,
    this.isLiked = false,
    this.onChanged,
  });

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> {
  late bool _isLiked;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.isLiked;
  }

  @override
  void didUpdateWidget(covariant LikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLiked != widget.isLiked) {
      _isLiked = widget.isLiked;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final next = !_isLiked;
        setState(() => _isLiked = next);
        widget.onChanged?.call(next);
      },
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
  final bool isFavorite;
  final ValueChanged<bool>? onFavoriteChanged;

  const ItineraryCard({
    super.key,
    required this.item,
    this.isFavorite = false,
    this.onFavoriteChanged,
  });

  Widget _buildImageFallback() {
    return Container(
      color: Colors.grey[200],
      alignment: Alignment.center,
      child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
    );
  }

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
                placeholder: (context, url) => Container(color: Colors.grey[200]),
                errorWidget: (context, url, error) => _buildImageFallback(),
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
            Positioned(
              top: 12,
              right: 12,
              child: LikeButton(
                isLiked: isFavorite,
                onChanged: onFavoriteChanged,
              ),
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
            DefaultAvatar(
              radius: 12,
              imageUrl: item.authorAvatar,
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
  final bool showFavorite;
  final ValueChanged<bool>? onFavoriteChanged;

  const ActivityCard({
    super.key,
    required this.item,
    this.showFavorite = true,
    this.onFavoriteChanged,
  });

  Widget _buildImageFallback() {
    return Container(
      color: Colors.grey[200],
      alignment: Alignment.center,
      child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 4 / 3,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey[200]),
                  errorWidget: (context, url, error) => _buildImageFallback(),
                ),
              ),
              if (showFavorite)
                Positioned(
                  top: 8,
                  right: 8,
                  child: LikeButton(
                    size: 16,
                    isLiked: item.isFavorite,
                    onChanged: onFavoriteChanged,
                  ),
                ),
            ],
          ),
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
              item.rating.toStringAsFixed(1),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _ReviewCountLabel(
                count: item.reviewCount,
                compact: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                item.address.trim().isEmpty ? 'Đang cập nhật địa chỉ' : item.address,
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
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

class RestaurantCard extends StatelessWidget {
  final CityRestaurant item;
  final bool showFavorite;
  final ValueChanged<bool>? onFavoriteChanged;

  const RestaurantCard({
    super.key,
    required this.item,
    this.showFavorite = true,
    this.onFavoriteChanged,
  });

  Widget _buildImageFallback() {
    return Container(
      color: Colors.grey[200],
      alignment: Alignment.center,
      child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 4 / 3,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey[200]),
                  errorWidget: (context, url, error) => _buildImageFallback(),
                ),
              ),
              if (showFavorite)
                Positioned(
                  top: 8,
                  right: 8,
                  child: LikeButton(
                    size: 16,
                    isLiked: item.isFavorite,
                    onChanged: onFavoriteChanged,
                  ),
                ),
            ],
          ),
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
              child: _ReviewCountLabel(
                count: item.reviewCount,
                compact: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                item.address.trim().isEmpty ? 'Đang cập nhật địa chỉ' : item.address,
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
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
  final bool showFavorite;
  final ValueChanged<bool>? onFavoriteChanged;

  const HotelCard({
    super.key,
    required this.item,
    this.showFavorite = true,
    this.onFavoriteChanged,
  });

  Widget _buildImageFallback() {
    return Container(
      color: Colors.grey[200],
      alignment: Alignment.center,
      child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 4 / 3,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey[200]),
                  errorWidget: (context, url, error) => _buildImageFallback(),
                ),
              ),
              if (showFavorite)
                Positioned(
                  top: 8,
                  right: 8,
                  child: LikeButton(
                    size: 16,
                    isLiked: item.isFavorite,
                    onChanged: onFavoriteChanged,
                  ),
                ),
            ],
          ),
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
              child: _ReviewCountLabel(
                count: item.reviewCount,
                compact: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 1),
        item.price.trim().isNotEmpty && item.price != 'Liên hệ'
            ? RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black, fontSize: 13),
                  children: [
                    const TextSpan(
                      text: 'Từ ',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    TextSpan(
                      text: item.price,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    const TextSpan(
                      text: '/đêm',
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              )
            : const Text(
                'Liên hệ giá',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
        const SizedBox(height: 3),
        Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                item.address,
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
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

class _ReviewCountLabel extends StatelessWidget {
  final int count;
  final bool compact;

  const _ReviewCountLabel({
    required this.count,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.rate_review_outlined,
          size: compact ? 12 : 14,
          color: const Color(0xFF64748B),
        ),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            '${_formatReviewCount(count)} đánh giá',
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

String _formatReviewCount(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}tr';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}k';
  }
  return value.toString();
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
