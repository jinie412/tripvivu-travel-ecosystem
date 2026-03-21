import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class SeeAllScreen extends StatelessWidget {
  final String title;
  final List<Widget> items;
  final VoidCallback? onAddTap;

  const SeeAllScreen({
    super.key,
    required this.title,
    required this.items,
    this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: onAddTap != null
          ? FloatingActionButton.extended(
              onPressed: onAddTap,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_location_alt_outlined, color: Colors.white),
              label: const Text('Thêm địa điểm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
      body: Column(
        children: [
          // Premium Blue Header
          Container(
            color: AppColors.primary,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              bottom: 24,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: AppColors.primary, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Custom Search Bar for consistency
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
                          'Tìm kiếm ${title.toLowerCase()}...',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 20),
              itemBuilder: (_, i) => items[i],
            ),
          ),
        ],
      ),
    );
  }
}
