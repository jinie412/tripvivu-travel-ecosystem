import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:travel_advisor_mobile/features/review/presentation/screens/rate_itinerary_screen.dart';
import '../../domain/entities/itinerary_entity.dart';

/// Card lịch trình "Đã đi" — có badge "ĐÃ ĐI" + rating ⭐ thay cho progress bar.
class ItineraryCompletedCard extends StatelessWidget {
  final ItineraryEntity item;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ItineraryCompletedCard({
    super.key,
    required this.item,
    this.onTap,
    this.onEdit,
    this.onDelete,
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
                  Text('Xóa',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 120,
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
            child: Row(
              children: [
                // ── Ảnh bên trái ───────────────────────────────────────────
                SizedBox(
                  width: 120,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildImage(),
                      // Badge "ĐÃ ĐI" góc trên trái
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF34A853),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'ĐÃ ĐI',
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
                  ),
                ),
                // ── Nội dung bên phải ──────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Tiêu đề + menu
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1C1C1E),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
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
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: item.rating == null ? const Color(0xFF0EA5E9) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.rating == null ? 'Đánh giá' : 'Xem đánh giá',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: item.rating == null ? Colors.white : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Ngày
                        Text(
                          '${item.durationDays} Ngày · ${_formatDuration()}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Rating
                        if (item.rating != null)
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  size: 16, color: Color(0xFFFFA500)),
                              const SizedBox(width: 3),
                              Text(
                                '${item.rating}/5',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1C1C1E),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
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
      errorWidget: (context, url, error) =>
          Container(color: Color(item.placeholderColor)),
    );
  }

  String _formatDuration() {
    if (item.startDate == null || item.endDate == null) return '';
    final months = ['', 'Th1', 'Th2', 'Th3', 'Th4', 'Th5', 'Th6',
                     'Th7', 'Th8', 'Th9', 'Th10', 'Th11', 'Th12'];
    return '${months[item.startDate!.month]} ${item.startDate!.year}';
  }
}
