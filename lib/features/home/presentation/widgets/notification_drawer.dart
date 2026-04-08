import 'package:flutter/material.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';

class NotificationDrawer extends StatelessWidget {
  const NotificationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Thông báo',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.background),
            // List of notifications
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildNotificationItem(
                    icon: Icons.map,
                    iconColor: AppColors.primary,
                    iconBgColor: AppColors.blobLight,
                    title: 'Lịch trình sắp diễn ra',
                    message: 'Chuyến du lịch khám phá Đà Lạt của bạn sẽ bắt đầu vào ngày mai. Đừng quên kiểm tra hành lý nhé!',
                    time: '5 phút trước',
                    isUnread: true,
                  ),
                  _buildNotificationItem(
                    icon: Icons.star_border,
                    iconColor: Colors.orange,
                    iconBgColor: Colors.orange.withValues(alpha: 0.1),
                    title: 'Đánh giá địa điểm',
                    message: 'Bạn cảm thấy Thác Pongour như thế nào? Hãy để lại đánh giá để nhận thêm điểm thưởng.',
                    time: '2 giờ trước',
                    isUnread: true,
                  ),
                  _buildNotificationItem(
                    icon: Icons.restaurant_menu,
                    iconColor: Colors.green,
                    iconBgColor: Colors.green.withValues(alpha: 0.1),
                    title: 'Đơn hàng ẩm thực đã sẵn sàng',
                    message: 'Món Bánh mì xíu mại (#TRV123) của bạn đã chuẩn bị xong. Vui lòng đến nhận món.',
                    time: 'Hôm qua',
                    isUnread: false,
                  ),
                  _buildNotificationItem(
                    icon: Icons.info_outline,
                    iconColor: Colors.blueAccent,
                    iconBgColor: Colors.blueAccent.withValues(alpha: 0.1),
                    title: 'Thông báo hệ thống',
                    message: 'Chúng tôi vừa cập nhật thêm tính năng gợi ý món ăn tự động theo vị trí của bạn.',
                    time: '2 ngày trước',
                    isUnread: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String message,
    required String time,
    required bool isUnread,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: isUnread ? AppColors.blobLight.withValues(alpha: 0.3) : Colors.transparent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(left: 8),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                    fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
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