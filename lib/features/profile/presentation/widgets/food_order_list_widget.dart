import 'package:flutter/material.dart';
import '../../domain/entities/activity_item_entity.dart';

class FoodOrderListWidget extends StatelessWidget {
  final List<ActivityItemEntity> items;

  const FoodOrderListWidget({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          'Chưa có đơn hàng.',
          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
        ),
      );
    }

    return Column(
      children: items.map((item) {
        String statusText = '';
        Color statusColor = Colors.grey;
        
        if (item.status == ActivityStatus.preparing) {
          statusText = 'Đang chuẩn bị';
          statusColor = Colors.orange;
        } else if (item.status == ActivityStatus.delivered) {
          statusText = 'Đã giao';
          statusColor = Colors.green;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.code ?? '',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 12,
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              )
            ],
          ),
        );
      }).toList(),
    );
  }
}
