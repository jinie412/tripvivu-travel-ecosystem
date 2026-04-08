import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/features/profile/domain/entities/activity_item_entity.dart';

class ActivityListWidget extends StatelessWidget {
  final List<ActivityItemEntity> items;

  const ActivityListWidget({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          'Chưa có dữ liệu.',
          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
        ),
      );
    }

    return Column(
      children: items.map((item) {
        String tag = '';
        Color tagColor = Colors.transparent;
        Color tagTextColor = Colors.transparent;

        if (item.type == ActivityType.itinerary) {
          tag = 'Địa điểm sắp đến';
          tagColor = AppColors.primary;
          tagTextColor = Colors.white;
        } else if (item.type == ActivityType.rated) {
          tag = 'Đã đánh giá';
          tagColor = AppColors.primary.withValues(alpha: 0.1);
          tagTextColor = AppColors.primary;
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (tag.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: tagColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 10,
                      color: tagTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                item.title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              if (item.status == ActivityStatus.pendingReview)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'Chờ bạn chia sẻ',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              if (item.rating != null || item.date != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      if (item.rating != null) ...[
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: Color(0xFFFFA500),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.rating.toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      if (item.date != null)
                        Text(
                          DateFormat('dd/MM/yyyy').format(item.date!),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}