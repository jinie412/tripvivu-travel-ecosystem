import 'package:flutter/material.dart';

import '../../../../core/widgets/net_image.dart';

class ReplaceLocationSection extends StatelessWidget {
  const ReplaceLocationSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Thay thế hoặc thêm địa điểm',
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold, 
                color: Color(0xFF1E293B),
              ),
            ),
            IconButton(
              onPressed: () {}, 
              icon: const Icon(Icons.close, size: 18, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm địa điểm mới...',
              hintStyle: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
              icon: Icon(Icons.search, size: 20, color: Color(0xFF94A3B8)),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Row(
          children: [
            Icon(Icons.auto_awesome, size: 18, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              'Địa điểm gợi ý',
              style: TextStyle(
                fontSize: 14, 
                fontWeight: FontWeight.bold, 
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _suggestionCard(
                'Bưu điện Thành phố',
                'Dự kiến: +15 phút',
                4.8,
                'https://images.unsplash.com/photo-1570737117716-43b98c3639be?w=400&q=80',
              ),
              const SizedBox(width: 12),
              _suggestionCard(
                'Nhà thờ Đức Bà',
                'Dự kiến: +5 phút',
                4.7,
                'https://images.unsplash.com/photo-1596401057633-1463e6398b1b?w=400&q=80',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _suggestionCard(String title, String duration, double rating, String imageUrl) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: NetImage(url: imageUrl, height: 100, width: 160, fit: BoxFit.cover),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, size: 10, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        rating.toString(),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    duration,
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
