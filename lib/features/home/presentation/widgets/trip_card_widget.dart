import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:travel_advisor_mobile/core/widgets/net_image.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/trip_suggestion.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/cubit/itinerary_cubit.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/screens/itinerary_summary_screen.dart';

class TripCardWidget extends StatefulWidget {
  final TripSuggestion item;

  const TripCardWidget({super.key, required this.item});

  @override
  State<TripCardWidget> createState() => _TripCardWidgetState();
}

class _TripCardWidgetState extends State<TripCardWidget> {
  bool _isLiked = false;

  void _toggleLike() {
    setState(() => _isLiked = !_isLiked);
    if (_isLiked) {
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
    final cubit = context.read<ItineraryCubit>();
    return GestureDetector(
      onTap: () {
        cubit.selectItinerary(widget.item.id);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: cubit,
              child: ItinerarySummaryScreen(itineraryId: widget.item.id),
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 170, // Slightly smaller than 230 to fit text
                  width: double.infinity,
                  child: NetImage(
                    url: widget.item.imageUrl,
                    placeholderColor: widget.item.placeholderColor,
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: _toggleLike,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white,
                    child: Icon(
                      _isLiked ? Icons.favorite : Icons.favorite_border,
                      color: _isLiked ? Colors.red : Colors.grey,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 8),
          // Row 1: Days + Location
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                widget.item.days,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.item.location,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Row 2: Avatar + Author + Views + Likes
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundImage: NetworkImage('https://i.pravatar.cc/100?u=${widget.item.id}'), // Móc avatar tạm
                backgroundColor: Colors.grey[200],
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Traveler', // Móc tên tác giả tạm
                  style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.visibility_outlined, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(widget.item.views, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(width: 8),
              const Icon(Icons.favorite, size: 14, color: Colors.redAccent),
              const SizedBox(width: 4),
              Text(widget.item.likes, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(width: 8), // Thụt vào một xíu
            ],
          ),
        ],
      ),
    );
  }
}