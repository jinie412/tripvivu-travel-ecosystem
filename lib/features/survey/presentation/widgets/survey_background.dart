import 'package:flutter/material.dart';

class SurveyBackground extends StatelessWidget {
  const SurveyBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top right subtle blob
        Positioned(
          top: -120,
          right: -60,
          child: _blob(320, const Color(0xFFB8D8F8), 0.3),
        ),
        // Bottom left subtle blob
        Positioned(
          bottom: -80,
          left: -40,
          child: _blob(240, const Color(0xFFD6ECFF), 0.4),
        ),
      ],
    );
  }

  Widget _blob(double size, Color color, double alpha) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: alpha),
        ),
      );
}
