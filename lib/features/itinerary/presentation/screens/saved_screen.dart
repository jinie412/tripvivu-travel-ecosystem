import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 24,
            left: 24,
            right: 24,
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Scaffold.of(context).openDrawer(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: const Icon(Icons.menu, size: 20, color: Color(0xFF374151)),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Đã lưu',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite, size: 56, color: Color(0xFFBDBDBD)),
                SizedBox(height: 16),
                Text(
                  'Chưa có nội dung',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
