import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:travel_advisor_mobile/features/review/presentation/screens/rate_itinerary_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/itinerary_entity.dart';

/// Card lịch trình (Sắp đi / Nháp) — có ảnh, badge ngày, progress bar.
///
/// Vuốt sang trái để hiện nút Sửa (xanh) + Xóa (đỏ).
class ItineraryCard extends StatelessWidget {
  final ItineraryEntity item;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const ItineraryCard({
    super.key,
    required this.item,
    this.onEdit,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Slidable(
        key: ValueKey(item.id),
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.4,
          children: [
            // ── Nút Xóa ──
            CustomSlidableAction(
              onPressed: (_) => onDelete?.call(),
              backgroundColor: const Color(0xFFEF5350),
              foregroundColor: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline, size: 22),
                  SizedBox(height: 4),
                  Text('Xóa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Ảnh + badge ngày ──────────────────────────────────────────
                SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildImage(),
                      // Gradient overlay phía dưới để text dễ đọc.
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.45),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Badge ngày ở góc dưới bên trái.
                      if (item.startDate != null && item.endDate != null)
                        Positioned(
                          bottom: 10,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _formatDateRange(item.startDate!, item.endDate!),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      // Badge "Đã đi" ở góc trên bên trái
                      if (item.status == ItineraryStatus.completed)
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50), // Green for completed
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'ĐÃ ĐI',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // ── Nội dung bên dưới ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tiêu đề + menu 3 chấm
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1C1C1E),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (item.status == ItineraryStatus.completed)
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RateItineraryScreen(
                                      itineraryId: item.id,
                                      isReadOnly: item.rating != null,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: item.rating == null ? AppColors.primary : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  item.rating == null ? 'Đánh giá' : 'Xem đánh giá',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: item.rating == null ? Colors.white : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Chi phí + Số ngày
                      Row(
                        children: [
                          Icon(Icons.monetization_on_outlined,
                              size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            _formatCost(item.estimatedCost, item.currency),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.calendar_today_outlined,
                              size: 14, color: Color(0xFF6B7280)),
                          const SizedBox(width: 4),
                          Text(
                            '${item.durationDays} Ngày',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Progress bar
                      _buildProgressBar(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (item.imageUrl == null || item.imageUrl!.isEmpty) {
      return Container(color: Color(item.placeholderColor));
    }
    return CachedNetworkImage(
      imageUrl: item.imageUrl!,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(color: Color(item.placeholderColor)),
      errorWidget: (context, url, error) => Container(color: Color(item.placeholderColor)),
    );
  }

  Widget _buildProgressBar() {
    final percent = (item.progress * 100).toInt();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Thanh progress
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: item.progress,
            minHeight: 6,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: AlwaysStoppedAnimation<Color>(
              item.progress >= 0.7
                  ? AppColors.primary
                  : const Color(0xFFFFA500),
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Phần trăm
        Text(
          '$percent%',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  String _formatDateRange(DateTime start, DateTime end) {
    final fmt = DateFormat('dd/MM');
    return '${fmt.format(start)} - ${fmt.format(end)}';
  }

  String _formatCost(double cost, String currency) {
    if (cost <= 0) return 'Chưa có';
    final fmt = NumberFormat('#,###', 'vi_VN');
    return '${fmt.format(cost)} $currency';
  }
}
