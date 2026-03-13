import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Trạng thái rỗng — hiển thị khi chưa có lịch trình nào.
///
/// Gồm icon bản đồ, text hướng dẫn, và nút "⊕ Tạo lịch trình".
class ItineraryEmptyView extends StatelessWidget {
  final VoidCallback? onCreateTap;
  const ItineraryEmptyView({super.key, this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon bản đồ lớn (giống Figma)
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F4FD),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.map_outlined,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Bạn chưa có lịch trình nào',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1C1E),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Bắt đầu tạo chuyến đi đầu tiên của bạn.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            // Nút tạo lịch trình
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onCreateTap,
                icon: const Icon(Icons.add_circle_outline, size: 20),
                label: const Text(
                  'Tạo lịch trình',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
