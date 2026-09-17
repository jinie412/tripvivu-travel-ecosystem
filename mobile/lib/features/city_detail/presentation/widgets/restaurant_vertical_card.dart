import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/features/city_detail/domain/entities/city_entities.dart';

class RestaurantVerticalCard extends StatefulWidget {
  final CityRestaurant item;
  final bool showFavorite;
  final Future<bool> Function(bool isFavorite)? onFavoriteChanged;

  const RestaurantVerticalCard({
    super.key,
    required this.item,
    this.showFavorite = true,
    this.onFavoriteChanged,
  });

  @override
  State<RestaurantVerticalCard> createState() => _RestaurantVerticalCardState();
}

class _RestaurantVerticalCardState extends State<RestaurantVerticalCard> {
  late bool _isFavorite;
  bool _isUpdatingFavorite = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.item.isFavorite;
  }

  @override
  void didUpdateWidget(covariant RestaurantVerticalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.isFavorite != widget.item.isFavorite) {
      _isFavorite = widget.item.isFavorite;
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isUpdatingFavorite) return;

    final nextFavorite = !_isFavorite;
    setState(() {
      _isFavorite = nextFavorite;
      _isUpdatingFavorite = true;
    });

    try {
      final success =
          await widget.onFavoriteChanged?.call(nextFavorite) ?? true;
      if (!success) {
        if (!mounted) return;
        setState(() {
          _isFavorite = !nextFavorite;
          _isUpdatingFavorite = false;
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _isUpdatingFavorite = false;
      });
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextFavorite
                ? 'Đã lưu vào danh mục yêu thích'
                : 'Đã xoá khỏi danh mục yêu thích',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isFavorite = !nextFavorite;
        _isUpdatingFavorite = false;
      });
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể cập nhật yêu thích. Vui lòng thử lại.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOpenStatus =
        widget.item.status.contains('Đang mở') ||
        widget.item.status.toLowerCase().contains('dang mo');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.premiumSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.premiumBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.premiumNavy.withValues(alpha: .07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Section
              SizedBox(
                width: 100,
                height: 100,
                child: CachedNetworkImage(
                  imageUrl: widget.item.imageUrl,
                  fit: BoxFit.cover,
                  memCacheWidth:
                      300, // thumbnail 100dp — không giải mã full-res
                  placeholder: (context, url) =>
                      Container(color: Colors.grey[200]),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),

              // Info Section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.premiumNavy,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.showFavorite)
                            GestureDetector(
                              onTap: _toggleFavorite,
                              child: Opacity(
                                opacity: _isUpdatingFavorite ? 0.5 : 1,
                                child: Icon(
                                  _isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: _isFavorite ? Colors.red : Colors.grey,
                                  size: 24,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _RatingReviewRow(
                        rating: widget.item.rating,
                        reviewCount: widget.item.reviewCount,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            color: Colors.grey[600],
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.item.address,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (widget.item.status.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.item.status,
                          style: TextStyle(
                            color: isOpenStatus
                                ? Colors.grey[700]
                                : Colors.red[400],
                            fontSize: 12,
                            fontWeight: isOpenStatus
                                ? FontWeight.normal
                                : FontWeight.w500,
                          ),
                        ),
                      ],
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

class _RatingReviewRow extends StatelessWidget {
  final double rating;
  final int reviewCount;

  const _RatingReviewRow({required this.rating, required this.reviewCount});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _InfoPill(
          icon: Icons.star_rounded,
          iconColor: Colors.amber,
          label: rating.toStringAsFixed(1),
        ),
        _InfoPill(
          icon: Icons.rate_review_outlined,
          iconColor: const Color(0xFF2563EB),
          label: '${_formatReviewCount(reviewCount)} đánh giá',
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;

  const _InfoPill({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
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
