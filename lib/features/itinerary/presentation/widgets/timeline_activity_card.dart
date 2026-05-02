import 'package:flutter/material.dart';
import 'package:travel_advisor_mobile/core/widgets/net_image.dart';

import 'package:intl/intl.dart';

import 'package:travel_advisor_mobile/core/constants/app_colors.dart';
import 'package:travel_advisor_mobile/core/constants/app_sizes.dart';
import 'package:travel_advisor_mobile/core/constants/app_text_styles.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_activity_entity.dart';
import 'package:travel_advisor_mobile/core/utils/demo_review_store.dart';

class TimelineActivityCard extends StatelessWidget {
  final ItineraryActivityEntity activity;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onAddTap;
  final VoidCallback? onEditTap;
  final VoidCallback? onDeleteTap;
  final VoidCallback? onReplaceTap;
  final VoidCallback? onCardTap;
  final VoidCallback? onCardLongPress;
  final VoidCallback? onStartTimeTap;
  final VoidCallback? onEndTimeTap;
  final VoidCallback? onRateTap;
  final int day;
  final bool isHighlighted;

  const TimelineActivityCard({
    super.key,
    required this.activity,
    this.isFirst = false,
    this.isLast = false,
    this.onAddTap,
    this.onEditTap,
    this.onDeleteTap,
    this.onReplaceTap,
    this.onCardTap,
    this.onCardLongPress,
    this.onStartTimeTap,
    this.onEndTimeTap,
    this.onRateTap,
    required this.day,
    this.isHighlighted = false,
  });

  String _formatReviewCount(int? count) {
    if (count == null) return '0';
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1).replaceAll('.0', '')}k';
    }
    return count.toString();
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ', decimalDigits: 0).format(amount);
  }

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
          isCompleted: activity.status == ActivityStatus.daDi,
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
    bool isCompleted = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Indicator
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 50), // Co dãn theo nội dung, tối thiểu 50
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: label.contains('Tham quan') ? onStartTimeTap : onEndTimeTap,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                    child: Text(
                      time,
                      style: AppTextStylesExt.bodySmall.copyWith(
                        color: AppColors.primary, // Đổi màu để nhận diện có thể bấm
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        decoration: TextDecoration.underline, // Gạch chân gợi ý
                        decorationStyle: TextDecorationStyle.dashed,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.s8),
                isCompleted
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 5), // padding 5 + size 20 = 30 height
                        child: Icon(
                          Icons.check_circle,
                          size: 20,
                          color: AppColorsExt.success,
                        ),
                      )
                    : Container(
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
    // 🔧 DEMO SYNC: Check if user has rated this in current session
    final double? userRating = DemoReviewStore.getLocationRating(activity.id);
    final bool hasUserRated = userRating != null;

    return InkWell(
      onTap: onCardTap,
      onLongPress: onCardLongPress,
      borderRadius: BorderRadius.circular(AppSizes.r24),
      child: Container(
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
          border: Border.all(
            color: isHighlighted 
                ? AppColors.primary 
                : AppColorsExt.divider.withAlpha(40),
            width: isHighlighted ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            NetImage(
              url: activity.imageUrl,
              width: 100,
              height: 125,
              borderRadius: AppSizes.r24, // Assuming we want the same curve as the card
              fit: BoxFit.cover,
            ),
            const SizedBox(width: AppSizes.s12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.s8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
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
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.more_vert, color: Color(0xFF94A3B8), size: 20),
                              onPressed: () {}, // Handled by onCardTap for now or can add PopupMenu
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
                        height: 1.2,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSizes.s4),
                    // Price Tag
                    if (activity.isFree)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColorsExt.success.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'MIỄN PHÍ',
                          style: AppTextStylesExt.captionSmall.copyWith(
                            color: AppColorsExt.success,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      )
                    else
                      Row(
                        children: [
                          Text(
                            _formatCurrency(activity.price),
                            style: AppTextStylesExt.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Vé vào cửa',
                            style: AppTextStylesExt.captionSmall.copyWith(
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: AppSizes.s8),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Color(0xFFFFC107), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${activity.rating?.toStringAsFixed(1) ?? "0.0"} (${_formatReviewCount(activity.reviewCount)})',
                          style: AppTextStylesExt.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                        if (activity.status == ActivityStatus.daDi) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: onRateTap,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Flexible(
                                    child: hasUserRated 
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.star_rounded, size: 12, color: Color(0xFF10B981)),
                                            const SizedBox(width: 2),
                                            Text(
                                              '$userRating',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF10B981),
                                              ),
                                            ),
                                          ],
                                        )
                                      : Text(
                                          '(Đánh giá)',
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: const Color(0xFF2563EB).withValues(alpha: 0.8),
                                            fontStyle: FontStyle.italic,
                                            decoration: TextDecoration.underline,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
          Flexible(
            child: Text(
              activity.transportInfo ?? '10-20 phút di chuyển',
              style: AppTextStylesExt.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColorsExt.textDark,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSizes.s8),
          const Icon(Icons.directions, size: 16, color: AppColors.primary),
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
