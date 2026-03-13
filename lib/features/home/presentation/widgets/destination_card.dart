import 'package:flutter/material.dart';
import '../../domain/entities/destination.dart';
import '../../../../core/widgets/net_image.dart';

class DestinationCard extends StatelessWidget {
  final Destination item;

  const DestinationCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: NetImage(
            url: item.imageUrl,
            placeholderColor: item.placeholderColor,
            borderRadius: 16),
      ),
      const SizedBox(height: 6),
      Text(
        item.name,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1C1C1E)),
      ),
    ]);
  }
}
