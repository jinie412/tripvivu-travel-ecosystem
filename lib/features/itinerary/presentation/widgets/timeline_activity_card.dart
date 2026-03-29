import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/itinerary_activity_entity.dart';

class TimelineActivityCard extends StatelessWidget {
  final ItineraryActivityEntity activity;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onAddTap;
  final VoidCallback? onEditTap;
  final VoidCallback? onDeleteTap;

  const TimelineActivityCard({
    super.key,
    required this.activity,
    this.isFirst = false,
    this.isLast = false,
    this.onAddTap,
    this.onEditTap,
    this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Activity Item
        _buildItem(
          context,
          time: activity.startTime,
          label: 'Tham quan trong 3 giờ',
          icon: Icons.location_on,
          content: _buildActivityCard(context),
          showLine: true,
        ),
        
        // 2. Transition Item (if exists)
        if (activity.transportInfo != null)
          _buildItem(
            context,
            time: activity.endTime,
            label: 'Di chuyển đến điểm tiếp theo',
            icon: Icons.directions_car,
            content: _buildTransitionChip(),
            showLine: !isLast,
            isTransition: true,
          ),
      ],
    );
  }

  Widget _buildItem(
    BuildContext context, {
    required String time,
    required String label,
    required IconData icon,
    required Widget content,
    required bool showLine,
    bool isTransition = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Indicator
          SizedBox(
            width: 45,
            child: Column(
              children: [
                Text(
                  time,
                  style: AppTextStylesExt.bodySmall.copyWith(
                    color: AppColorsExt.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: AppSizes.s8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColorsExt.profileBlue.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 18, color: AppColorsExt.profileBlue),
                ),
                if (showLine)
                  Expanded(
                    child: Center(
                      child: CustomPaint(
                        size: const Size(2, double.infinity),
                        painter: _DashedLinePainter(),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: AppSizes.s24),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.s12),
          // Content Area
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isTransition ? AppSizes.s12 : AppSizes.s8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 38), // Push content down to align roughly with icon
                  Text(
                    label,
                    style: AppTextStylesExt.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: AppSizes.s8),
                  content,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(right: AppSizes.s8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.r24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColorsExt.divider.withAlpha(40)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(AppSizes.r24)),
            child: Image.network(
              activity.imageUrl,
              width: 100,
              height: 110,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: AppSizes.s12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.s12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                   Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          activity.title,
                          style: AppTextStyles.heading2.copyWith(
                            fontSize: 15,
                            color: AppColorsExt.textDark,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (onEditTap != null || onDeleteTap != null)
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                onEditTap?.call();
                              } else if (value == 'delete') {
                                onDeleteTap?.call();
                              }
                            },
                            icon: const Icon(
                              Icons.more_vert,
                              size: 18,
                              color: Color(0xFF94A3B8),
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            splashRadius: 20,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                                    const SizedBox(width: 8),
                                    Text('Chỉnh sửa', style: AppTextStyles.body.copyWith(fontSize: 14)),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    const Icon(Icons.delete_outline, size: 18, color: AppColorsExt.error),
                                    const SizedBox(width: 8),
                                    Text('Xóa', style: AppTextStyles.body.copyWith(fontSize: 14, color: AppColorsExt.error)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.s4),
                  Text(
                    activity.address,
                    style: AppTextStylesExt.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.s8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Color(0xFFFFC107), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '3.679 (102)',
                        style: AppTextStylesExt.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
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
    );
  }

  Widget _buildTransitionChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.s16, vertical: AppSizes.s8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.r24),
        border: Border.all(color: AppColorsExt.divider.withAlpha(100)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            activity.transportInfo ?? '10-20 phút di chuyển',
            style: AppTextStylesExt.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColorsExt.textDark,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: AppSizes.s8),
          Icon(Icons.chevron_right, size: 16, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double dashHeight = 2, dashSpace = 4, startY = 2; // Small initial offset
    final paint = Paint()
      ..color = AppColorsExt.divider
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + 0.1), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
