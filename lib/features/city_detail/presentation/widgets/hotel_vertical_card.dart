import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/features/city_detail/domain/entities/city_entities.dart';

class HotelVerticalCard extends StatefulWidget {
  final CityHotel item;
  final bool showFavorite;
  final Future<bool> Function(bool isFavorite)? onFavoriteChanged;

  const HotelVerticalCard({
    super.key,
    required this.item,
    this.showFavorite = true,
    this.onFavoriteChanged,
  });

  @override
  State<HotelVerticalCard> createState() => _HotelVerticalCardState();
}

class _HotelVerticalCardState extends State<HotelVerticalCard> {
  late bool _isFavorite;
  bool _isUpdatingFavorite = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.item.isFavorite;
  }

  @override
  void didUpdateWidget(covariant HotelVerticalCard oldWidget) {
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
      final success = await widget.onFavoriteChanged?.call(nextFavorite) ?? true;
      if (!success) {
        if (!mounted) return;
        setState(() {
          _isFavorite = !nextFavorite;
          _isUpdatingFavorite = false;
        });
        return;
      }

      if (!mounted) return;
      setState(() => _isUpdatingFavorite = false);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text(
            nextFavorite
                ? 'Đã lưu vào danh mục yêu thích'
                : 'Đã xoá khỏi danh mục yêu thích',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isFavorite = !nextFavorite;
        _isUpdatingFavorite = false;
      });
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
          content: Text('Không thể cập nhật yêu thích. Vui lòng thử lại.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CachedNetworkImage(
                  imageUrl: widget.item.imageUrl,
                  fit: BoxFit.cover,
                  memCacheWidth: 300, // thumbnail 100dp — không giải mã full-res
                  placeholder: (context, url) =>
                      Container(color: Colors.grey[200]),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.error),
                ),
              ),
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
                                fontSize: 16,
                                color: Colors.black,
                              ),
                              maxLines: 1,
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
                      _HotelRatingReviewRow(
                        rating: widget.item.rating,
                        reviewCount: widget.item.reviewCount,
                      ),
                      // Luôn hiển thị dòng giá (trên phần địa chỉ): có giá thật
                      // thì "Từ ...", chưa có data giá thì "Liên hệ giá".
                      const SizedBox(height: 4),
                      Text(
                        widget.item.price.trim().isNotEmpty &&
                                widget.item.price != 'Liên hệ'
                            ? 'Từ ${widget.item.price}'
                            : 'Liên hệ giá',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      if (widget.item.address.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                color: Colors.grey[600], size: 14),
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

class _HotelRatingReviewRow extends StatelessWidget {
  final double rating;
  final int reviewCount;

  const _HotelRatingReviewRow({
    required this.rating,
    required this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _HotelInfoPill(
          icon: Icons.star_rounded,
          iconColor: Colors.amber,
          label: rating.toStringAsFixed(1),
        ),
        _HotelInfoPill(
          icon: Icons.rate_review_outlined,
          iconColor: const Color(0xFF2563EB),
          label: '${_formatHotelReviewCount(reviewCount)} đánh giá',
        ),
      ],
    );
  }
}

class _HotelInfoPill extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;

  const _HotelInfoPill({
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

String _formatHotelReviewCount(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}tr';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}k';
  }
  return value.toString();
}
