import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';

import 'package:travel_advisor_mobile/features/city_detail/domain/entities/city_entities.dart';

class ActivityVerticalCard extends StatefulWidget {
  final CityActivity item;
  final bool showFavorite;
  final bool showLocationIcon;
  final bool showDestinationStats;
  final ValueChanged<bool>? onFavoriteChanged;

  const ActivityVerticalCard({
    super.key,
    required this.item,
    this.showFavorite = true,
    this.showLocationIcon = true,
    this.showDestinationStats = false,
    this.onFavoriteChanged,
  });

  @override
  State<ActivityVerticalCard> createState() => _ActivityVerticalCardState();
}

class _ActivityVerticalCardState extends State<ActivityVerticalCard> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.item.isFavorite;
  }

  @override
  void didUpdateWidget(covariant ActivityVerticalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.isFavorite != widget.item.isFavorite) {
      _isFavorite = widget.item.isFavorite;
    }
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    widget.onFavoriteChanged?.call(_isFavorite);
    if (_isFavorite) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu vào danh mục yêu thích'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAddress = widget.item.address.trim().isNotEmpty;
    final hasStatus = widget.item.status.trim().isNotEmpty;
    final isOpenStatus =
        widget.item.status.contains('Đang mở') ||
        widget.item.status.contains('Äang má»Ÿ') ||
        widget.item.status.toLowerCase().contains('dang mo');

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
                              child: Icon(
                                _isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: _isFavorite ? Colors.red : Colors.grey,
                                size: 24,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      widget.showDestinationStats
                          ? _DestinationStatsRow(item: widget.item)
                          : _ActivityRatingRow(item: widget.item),
                      if (hasAddress) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (widget.showLocationIcon) ...[
                              Icon(
                                Icons.location_on_outlined,
                                color: Colors.grey[600],
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                            ],
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
                      if (hasStatus) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.item.status,
                          style: TextStyle(
                            color:
                                isOpenStatus ? Colors.grey[700] : Colors.red[400],
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

class _ActivityRatingRow extends StatelessWidget {
  final CityActivity item;

  const _ActivityRatingRow({required this.item});

  @override
  Widget build(BuildContext context) {
    // Pill style đồng bộ với RestaurantVerticalCard / HotelVerticalCard.
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _StatPill(
          icon: Icons.star_rounded,
          iconColor: Colors.amber,
          label: item.rating.toStringAsFixed(1),
        ),
        _StatPill(
          icon: Icons.rate_review_outlined,
          iconColor: const Color(0xFF2563EB),
          label: '${_formatCount(item.reviewCount)} đánh giá',
        ),
      ],
    );
  }
}

class _DestinationStatsRow extends StatelessWidget {
  final CityActivity item;

  const _DestinationStatsRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatPill(
          icon: Icons.star_rounded,
          iconColor: Colors.amber,
          label: item.rating > 0 ? item.rating.toStringAsFixed(1) : 'Chưa có',
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatPill(
            icon: Icons.rate_review_outlined,
            iconColor: const Color(0xFF2563EB),
            label: '${_formatCount(item.reviewCount)} đánh giá',
          ),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;

  const _StatPill({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: iconColor),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatCount(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}tr';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}k';
  }
  return value.toString();
}
