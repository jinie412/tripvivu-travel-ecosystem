import 'package:flutter/material.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';

class ConflictResolutionSheet extends StatelessWidget {
  final bool canExtend;
  final bool canReduce;
  final bool canAddDay;
  final String? errorMessage;
  final void Function(int) onSelect;

  const ConflictResolutionSheet({
    super.key,
    required this.canExtend,
    required this.canReduce,
    required this.canAddDay,
    this.errorMessage,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, color: Colors.blue[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'GỢI Ý',
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    color: Colors.blue[600], 
                    fontSize: 13,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700], size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: TextStyle(
                          color: Colors.red[800],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              const Text(
                'Lịch trình của bạn đã quá tải.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold, 
                  height: 1.4,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              'Thời gian hoạt động trong ngày đã hết. Vui lòng chọn một trong các phương án sau:',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13, 
                color: Color(0xFF64748B), 
              ),
            ),
            const SizedBox(height: 32),
            if (canExtend) ...[
              _optionCard(
                context,
                '1',
                'Kéo dài thời gian trong ngày',
                'Cho phép thêm thời gian',
                const Color(0xFFEFF6FF),
                const Color(0xFF2563EB),
                null,
                onTap: () => onSelect(1),
              ),
              const SizedBox(height: 16),
            ],
            if (canReduce) ...[
              _optionCard(
                context,
                '2',
                'Giảm giờ tham quan các nơi khác',
                'Tối ưu lại thời gian',
                const Color(0xFFECFDF5),
                const Color(0xFF10B981),
                null,
                onTap: () => onSelect(2),
              ),
              const SizedBox(height: 16),
            ],
            if (canAddDay) ...[
              _optionCard(
                context,
                '3',
                'Thêm 1 ngày vào lịch trình',
                'Kéo dài chuyến đi',
                const Color(0xFFFEE2E2),
                const Color(0xFFEF4444),
                null,
                onTap: () => onSelect(3),
              ),
              const SizedBox(height: 16),
            ],
            TextButton(
              onPressed: () => onSelect(0),
              child: const Text(
                'Hủy bỏ chỉnh sửa',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionCard(
    BuildContext context,
    String id,
    String title,
    String subtitle,
    Color bgColor,
    Color iconColor,
    String? imageUrl, {
    bool isRecommended = false,
    VoidCallback? onTap,
  }) {
    Widget card = GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isRecommended ? AppColors.primary : const Color(0xFFF1F5F9),
            width: isRecommended ? 2 : 1,
          ),
          boxShadow: [
            if (isRecommended)
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isRecommended ? AppColors.primary : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  id,
                  style: TextStyle(
                    color: isRecommended ? Colors.white : const Color(0xFF64748B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _tag(subtitle, bgColor, iconColor),
                ],
              ),
            ),
            if (imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  cacheWidth: 180, // thumbnail 60dp — không giải mã full-res
                ),
              ),
          ],
        ),
      ),
    );

    if (isRecommended) {
      card = Stack(
        clipBehavior: Clip.none,
        children: [
          card,
          Positioned(
            top: -12,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                'GỢI Ý TỐT NHẤT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: () => onSelect(0),
      child: card,
    );
  }

  Widget _tag(String text, Color bg, Color textCo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textCo,
        ),
      ),
    );
  }
}