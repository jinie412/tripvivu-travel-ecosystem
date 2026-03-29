import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ConflictResolutionSheet extends StatelessWidget {
  final VoidCallback onSelect;

  const ConflictResolutionSheet({super.key, required this.onSelect});

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
            Text(
              'Lịch trình của bạn đang gặp xung đột về thời gian tại Dinh Độc Lập.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold, 
                height: 1.4,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '“Chúng tôi gợi ý bạn nên chọn Phương án C để có thời gian nghỉ ngơi tốt hơn.”',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13, 
                color: Color(0xFF64748B), 
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 32),
            _optionCard(
              context,
              'A',
              'Giữ nguyên & Tối ưu lộ trình',
              '+15p di chuyển',
              const Color(0xFFEFF6FF),
              const Color(0xFF2563EB),
              'https://images.unsplash.com/photo-1526772662000-3f88f10405ff?w=400&q=80', // Map preview mock
            ),
            const SizedBox(height: 16),
            _optionCard(
              context,
              'B',
              'Bỏ qua điểm này',
              'Tiết kiệm 45.000₫',
              const Color(0xFFECFDF5),
              const Color(0xFF10B981),
              'https://images.unsplash.com/photo-1580519542036-c47de6196ba5?w=400&q=80', // Coin/Money mock
            ),
            const SizedBox(height: 16),
            _optionCard(
              context,
              'C',
              'Dời sang Ngày 2',
              'Lịch trình cân bằng',
              const Color(0xFFEFF6FF),
              const Color(0xFF2563EB),
              'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=400&q=80', // Zen/Balance mock
              isRecommended: true,
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Bỏ qua tất cả gợi ý',
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
    String tag,
    Color tagBg,
    Color tagText,
    String imageUrl, {
    bool isRecommended = false,
  }) {
    Widget card = Container(
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
                _tag(tag, tagBg, tagText),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
        ],
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
      onTap: onSelect,
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
