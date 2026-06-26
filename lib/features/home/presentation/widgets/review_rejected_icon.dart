import 'package:flutter/material.dart';

/// Icon "review bị từ chối": ngôi sao đánh giá + badge X đỏ góc dưới phải.
class ReviewRejectedIcon extends StatelessWidget {
  final double size;
  final Color color;

  const ReviewRejectedIcon({
    super.key,
    this.size = 22,
    this.color = const Color(0xFFC0392B),
  });

  @override
  Widget build(BuildContext context) {
    final badgeSize = size * 0.45;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.rate_review_outlined, size: size, color: color),
          Positioned(
            right: -badgeSize * 0.2,
            bottom: -badgeSize * 0.2,
            child: Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: badgeSize * 0.7,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
