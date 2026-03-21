import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ExploreHeader extends StatelessWidget {
  const ExploreHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        bottom: 24,
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Nút filter dạng tròn màu trắng
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.menu, color: AppColors.primary, size: 20),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Vị trí
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'VỊ TRÍ CỦA BẠN',
                          style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(
                      'QUẬN 1, HỒ CHÍ MINH',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Thanh tìm kiếm
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tìm kiếm điểm đến, món ăn...',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
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
