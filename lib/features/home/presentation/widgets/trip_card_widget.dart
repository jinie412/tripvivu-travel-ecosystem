import 'package:flutter/material.dart';
import '../../domain/entities/trip_suggestion.dart';
import '../../../../core/widgets/net_image.dart';

class TripCardWidget extends StatelessWidget {
  final TripSuggestion item;

  const TripCardWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          flex: 6,
          child: NetImage(
              url: item.imageUrl, placeholderColor: item.placeholderColor),
        ),
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C1C1E)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 12, color: Color(0xFF6B7280)),
                  const SizedBox(width: 3),
                  Text(item.days,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF6B7280))),
                  const SizedBox(width: 10),
                  const Icon(Icons.location_on_outlined,
                      size: 12, color: Color(0xFF6B7280)),
                  const SizedBox(width: 3),
                  Text(item.location,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF6B7280))),
                ]),
                Row(children: [
                  const Icon(Icons.remove_red_eye_outlined,
                      size: 12, color: Color(0xFF9E9E9E)),
                  const SizedBox(width: 3),
                  Text(item.views,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF9E9E9E))),
                  const SizedBox(width: 10),
                  const Icon(Icons.favorite, size: 12, color: Colors.redAccent),
                  const SizedBox(width: 3),
                  Text(item.likes,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF9E9E9E))),
                ]),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}
