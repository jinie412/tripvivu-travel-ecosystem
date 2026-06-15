import 'package:flutter/material.dart';

import 'package:travel_advisor_mobile/core/constants/app_colors.dart';
import 'package:travel_advisor_mobile/core/constants/app_sizes.dart';
import 'package:travel_advisor_mobile/core/theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _currentSort = 'Mới nhất';

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.r20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.s20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Mới nhất'),
                trailing: _currentSort == 'Mới nhất'
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  setState(() => _currentSort = 'Mới nhất');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('Chưa đọc'),
                trailing: _currentSort == 'Chưa đọc'
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  setState(() => _currentSort = 'Chưa đọc');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Header with Centered Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.s16, vertical: AppSizes.s8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 24, color: Colors.black87),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Hộp thư đến',
                        style: AppTextStyles.heading2.copyWith(
                          fontSize: 18,
                          color: AppColorsExt.textDark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.s48), // Padding to balance the IconButton
                ],
              ),
            ),

            const SizedBox(height: 8),
            // Divider removed
            const SizedBox(height: 8),

            // 3. Filter Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.s24),
              child: Row(
                children: [
                  _buildSortSelector(),
                  const SizedBox(width: 8),
                  _buildActiveSortTag(_currentSort),
                ],
              ),
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),

            // 4. Empty State (Moved to TopCenter with some padding)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 20, left: 16, right: 16),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Text(
                    'Không có cảnh báo hay tin nhắn vào lúc này',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 16, // Slightly smaller
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortSelector() {
    return GestureDetector(
      onTap: _showSortOptions,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Text(
              'Sắp xếp',
              style: AppTextStyles.body.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSortTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTextStyles.body.copyWith(
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
    );
  }
}