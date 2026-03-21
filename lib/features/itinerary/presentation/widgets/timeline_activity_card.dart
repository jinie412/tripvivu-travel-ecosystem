import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/itinerary_activity_entity.dart';
import '../screens/activity_edit_screen.dart';

class TimelineActivityCard extends StatelessWidget {
  final ItineraryActivityEntity activity;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onAddTap;

  const TimelineActivityCard({
    super.key,
    required this.activity,
    this.isFirst = false,
    this.isLast = false,
    this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline indicator
          SizedBox(
            width: 24,
            child: Column(
              children: [
                _buildStatusIndicator(),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: const Color(0xFFE5E7EB),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.startTime,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF3F4F6)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                activity.imageUrl,
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          activity.title,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1F2937),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        padding: EdgeInsets.zero,
                                        icon: const Icon(Icons.more_vert, size: 20, color: Color(0xFF94A3B8)),
                                        onSelected: (val) {
                                          if (val == 'edit') {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => ActivityEditScreen(activity: activity),
                                              ),
                                            );
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit_outlined, size: 20, color: Color(0xFF1E293B)),
                                                SizedBox(width: 8),
                                                Text('Chỉnh sửa'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                                SizedBox(width: 8),
                                                Text('Xóa', style: TextStyle(color: Colors.red)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    activity.address,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  if (activity.isFree)
                                    Row(
                                      children: [
                                        _label('MIỄN PHÍ', const Color(0xFFECFDF5), const Color(0xFF10B981)),
                                        const SizedBox(width: 8),
                                        _statusLabel(),
                                      ],
                                    )
                                  else 
                                    Row(
                                      children: [
                                        if (activity.price > 0) ...[
                                          Text('${activity.price.toInt()} VNĐ', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                          const SizedBox(width: 8),
                                          const Text('Vé vào cửa', style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
                                          const SizedBox(width: 8),
                                        ],
                                        _statusLabel(),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: Color(0xFFF3F4F6)),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () {},
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.near_me_outlined, size: 16, color: AppColors.primary),
                              SizedBox(width: 8),
                              Text('Chỉ đường', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (activity.transportInfo != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.arrow_downward, size: 10, color: Color(0xFF9CA3AF)),
                              const SizedBox(width: 8),
                              const Icon(Icons.directions_car, size: 12, color: Color(0xFF9CA3AF)),
                              const SizedBox(width: 8),
                              Text(activity.transportInfo!, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), fontStyle: FontStyle.italic)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildAddButton(),
                        ],
                      ),
                    )
                  else if (!isLast)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _buildAddButton(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return InkWell(
      onTap: onAddTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 14, color: Colors.white),
            ),
            const SizedBox(width: 8),
            const Text(
              'Thêm địa điểm',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    switch (activity.status) {
      case ActivityStatus.daDi:
        return Container(
          width: 16,
          height: 16,
          decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
          child: const Icon(Icons.check, size: 10, color: Colors.white),
        );
      case ActivityStatus.dangDi:
        return Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 4),
          ),
        );
      case ActivityStatus.diQua:
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF94A3B8), width: 2),
          ),
        );
      case ActivityStatus.chuaDi:
      default:
        return Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(color: Color(0xFFE2E8F0), shape: BoxShape.circle),
        );
    }
  }

  Widget _statusLabel() {
    switch (activity.status) {
      case ActivityStatus.daDi:
        return _label('ĐÃ ĐẾN', const Color(0xFFECFDF5), const Color(0xFF10B981));
      case ActivityStatus.dangDi:
        return _label('ĐANG ĐẾN', const Color(0xFFEFF6FF), AppColors.primary);
      case ActivityStatus.diQua:
        return _label('ĐÃ ĐI QUA', const Color(0xFFF1F5F9), const Color(0xFF64748B));
      case ActivityStatus.chuaDi:
      default:
        return _label('CHƯA ĐẾN', const Color(0xFFF8FAFC), const Color(0xFF94A3B8));
    }
  }

  Widget _label(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(fontSize: 8, color: textCol, fontWeight: FontWeight.bold)),
    );
  }
}
