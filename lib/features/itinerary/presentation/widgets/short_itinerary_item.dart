import 'package:flutter/material.dart';
import 'package:travel_advisor_mobile/core/theme/app_colors.dart';

class ShortItineraryItem extends StatelessWidget {
  final int dayNumber;
  final String date;
  final String totalCostText;
  final int locationCount;
  final String? distanceKmText;
  final String? sightseeingTimeText;
  final String? travelTimeText;
  final IconData icon;
  final VoidCallback? onTap;

  const ShortItineraryItem({
    super.key,
    required this.dayNumber,
    required this.date,
    required this.totalCostText,
    required this.locationCount,
    this.distanceKmText,
    this.sightseeingTimeText,
    this.travelTimeText,
    required this.icon,
    this.onTap,
  });

  Widget _statChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.premiumMuted),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 11, color: AppColors.premiumMuted),
        ),
      ],
    );
  }

  Widget _dayBadge() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.premiumSoftBlue,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Ngày',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.premiumMuted,
            ),
          ),
          Text(
            '$dayNumber',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Hàng trên: địa điểm + giờ tham quan. Hàng dưới: km + giờ di chuyển —
    // tách 2 hàng rõ ràng theo nhóm "ở lại" vs "di chuyển" thay vì 1 dòng
    // Wrap dồn hết, đọc sạch và dễ quét hơn.
    final topRow = <Widget>[
      _statChip(Icons.place_outlined, '$locationCount địa điểm'),
      if (sightseeingTimeText != null)
        _statChip(Icons.camera_alt_outlined, sightseeingTimeText!),
    ];
    final bottomRow = <Widget>[
      if (distanceKmText != null)
        _statChip(Icons.route_outlined, distanceKmText!),
      if (travelTimeText != null)
        _statChip(Icons.directions_car_filled_outlined, travelTimeText!),
    ];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF3F4F6)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Semantics(label: 'Ngày $dayNumber, $date', child: _dayBadge()),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 13, color: AppColors.premiumMuted),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          date,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1C1C1E),
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        totalCostText,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  if (topRow.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(spacing: 12, runSpacing: 6, children: topRow),
                  ],
                  if (bottomRow.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(spacing: 12, runSpacing: 6, children: bottomRow),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
