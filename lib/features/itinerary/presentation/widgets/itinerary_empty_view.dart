import 'package:flutter/material.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';

/// Trạng thái rỗng — hiển thị khi chưa có lịch trình nào.
class ItineraryEmptyView extends StatelessWidget {
  final VoidCallback? onCreateTap;

  const ItineraryEmptyView({super.key, this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Large Icon Background ─────────────────────────────────────────────
            Stack(
              alignment: Alignment.center,
              children: [
                // Inner Glow Circle
                Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFE0F2FE).withValues(alpha: 0.8),
                        const Color(0xFFEFF6FF).withValues(alpha: 0.4),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
                // Middle Circle
                Container(
                  width: 140,
                  height: 140,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                ),
                // Map Icon in a White Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.map_outlined,
                    size: 44,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
            // ── Text Content ────────────────────────────────────────────────────────
            Text(
              'Bạn chưa có lịch trình nào',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Bắt đầu tạo chuyến đi đầu tiên của bạn.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            // ── Action Button ───────────────────────────────────────────────────────
            SizedBox(
              width: 200,
              height: 56,
              child: ElevatedButton(
                onPressed: onCreateTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 8,
                  shadowColor: AppColors.primary.withValues(alpha: 0.4),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Tạo lịch trình',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}