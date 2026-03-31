import 'package:flutter/material.dart';

class StarRatingInput extends StatelessWidget {
  final double rating;
  final ValueChanged<double> onRatingChanged;
  final double size;
  final MainAxisAlignment mainAxisAlignment;

  const StarRatingInput({
    super.key,
    required this.rating,
    required this.onRatingChanged,
    this.size = 28,
    this.mainAxisAlignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        return GestureDetector(
          onTap: () => onRatingChanged(starValue.toDouble()),
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(
              starValue <= rating ? Icons.star_rounded : Icons.star_border_rounded,
              color: const Color(0xFFFFB020),
              size: size,
            ),
          ),
        );
      }),
    );
  }
}