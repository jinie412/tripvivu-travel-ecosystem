import 'package:flutter/material.dart';
import 'package:travel_advisor_mobile/core/widgets/net_image.dart';

import 'package:travel_advisor_mobile/core/constants/app_colors.dart';
import 'package:travel_advisor_mobile/core/constants/app_sizes.dart';
import 'package:travel_advisor_mobile/core/constants/app_text_styles.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_activity_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/tracking/data/models/tracking_models.dart';
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
  final VoidCallback? onViewDetailTap;
  final VoidCallback? onStartTimeTap;
  final VoidCallback? onEndTimeTap;
  final VoidCallback? onRateTap;
  final VoidCallback? onDirectionTap;
  final int day;
  final bool isHighlighted;
  final bool isEditMode;
  final bool isOpeningReview;
  final String? nextTransportInfo;

  /// Trạng thái theo dõi của địa điểm này (null = tracking chưa bật).
  final TrackingPlaceStatus? trackingStatus;

  /// Callback check-in thủ công "Tôi đã đến" khi tracking active.
  final VoidCallback? onCheckIn;

  /// Đang xử lý check-in (hiện loading spinner thay nút).
  final bool isCheckingIn;

  /// Trạng thái review từ backend: true=đã review, false=chưa, null=chưa load.
  final bool? hasReview;

  /// Đã ghé địa điểm này theo dữ liệu backend (geofence_visits).
  final bool backendIsVisited;

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
    this.onViewDetailTap,
    this.onStartTimeTap,
    this.onEndTimeTap,
    this.onRateTap,
    this.onDirectionTap,
    required this.day,
    this.isHighlighted = false,
    this.isEditMode = false,
    this.isOpeningReview = false,
    this.nextTransportInfo,
    this.trackingStatus,
    this.onCheckIn,
    this.isCheckingIn = false,
    this.hasReview,
    this.backendIsVisited = false,
  });

  String _formatReviewCount(int? count) {
    if (count == null) return '0';
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1).replaceAll('.0', '')}k';
    }
    return count.toString();
  }

  String _formatPrice(double price) {
    if (price >= 1_000_000) {
      final m = price / 1_000_000;
      return '${m == m.truncate() ? m.toInt() : m.toStringAsFixed(1)}M₫';
    }
    if (price >= 1_000) {
      return '${(price / 1_000).truncate()}k₫';
    }
    return '${price.toInt()}₫';
  }

  String _durationLabel() {
    if (_isAccommodationStart) return 'Nơi ở & điểm xuất phát';
    List<int> parts(String t) => t.split(':').map(int.parse).toList();
    try {
      final s = parts(activity.startTime);
      final e = parts(activity.endTime);
      final mins = (e[0] * 60 + e[1]) - (s[0] * 60 + s[1]);
      if (mins <= 0) return 'Tham quan';
      if (mins < 60) return 'Tham quan trong $mins phút';
      final h = mins ~/ 60;
      final m = mins % 60;
      if (m == 0) return 'Tham quan trong $h giờ';
      return 'Tham quan trong $h giờ $m phút';
    } catch (_) {
      return 'Tham quan';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAccommodationStart = _isAccommodationStart;

    return Column(
      children: [
        // 1. Activity Item
        _buildItem(
          context,
          time: activity.startTime,
          label: _durationLabel(),
          icon: isAccommodationStart ? Icons.hotel_rounded : Icons.location_on,
          content: _buildActivityCard(context),
          showLine: true,
          isCompleted:
              activity.status == ActivityStatus.daDi ||
              trackingStatus?.status == VisitStatus.visited ||
              backendIsVisited,
          isEditMode: isEditMode,
        ),

        // 2. Transition Item
        if (!isLast)
          _buildItem(
            context,
            time: activity.endTime,
            label: 'Di chuyển đến điểm tiếp theo',
            icon: Icons.directions_car,
            content: _buildTransitionChip(),
            showLine: true,
            isTransition: true,
            isEditMode: isEditMode,
          ),

        // 3. End Marker (last activity only)
        if (isLast)
          _buildItem(
            context,
            time: activity.endTime,
            label: 'Kết thúc hành trình',
            icon: Icons.flag_rounded,
            content: const SizedBox.shrink(),
            showLine: false,
            isTransition: true,
            isEditMode: isEditMode,
          ),
      ],
    );
  }

  bool get _isAccommodationStart {
    final category = (activity.category ?? '').toLowerCase();
    final isAccommodation =
        category.contains('lưu trú') ||
        category.contains('luu tru') ||
        category.contains('khách sạn') ||
        category.contains('khach san') ||
        category.contains('hotel');
    return isAccommodation && activity.startTime == activity.endTime;
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
    bool isEditMode = false,
  }) {
    String _formatTime(String t) {
      if (t.length >= 5) {
        return t.substring(0, 5);
      }
      return t;
    }
    
    final formattedTime = _formatTime(time);
    final isStartTime = label.contains('Tham quan');
    final isAccommodationStart = _isAccommodationStart;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Indicator
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 50),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                isEditMode
                    ? InkWell(
                        onTap: isStartTime ? onStartTimeTap : onEndTimeTap,
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 2,
                          ),
                          child: Text(
                            formattedTime,
                            style: AppTextStylesExt.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              decoration: TextDecoration.underline,
                              decorationStyle: TextDecorationStyle.dashed,
                            ),
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 2,
                        ),
                        child: Text(
                          formattedTime,
                          style: AppTextStylesExt.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                const SizedBox(height: AppSizes.s8),
                isCompleted
                    ? const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 5,
                        ), // padding 5 + size 20 = 30 height
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
                        child: Icon(
                          icon,
                          size: 18,
                          color: AppColorsExt.profileBlue,
                        ),
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
              padding: EdgeInsets.only(
                bottom: isTransition ? AppSizes.s12 : AppSizes.s8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        label,
                        style: AppTextStylesExt.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      if (isEditMode && !isTransition && !isAccommodationStart)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _smallEditAction(
                              Icons.swap_horiz_rounded,
                              const Color(0xFFF59E0B),
                              onReplaceTap,
                            ),
                            const SizedBox(width: 6),
                            _smallEditAction(
                              Icons.delete_outline_rounded,
                              const Color(0xFFEF4444),
                              onDeleteTap,
                            ),
                          ],
                        ),
                    ],
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

  bool get _isVisited =>
      activity.status == ActivityStatus.daDi ||
      trackingStatus?.status == VisitStatus.visited ||
      backendIsVisited;

  Widget _buildActivityCard(BuildContext context) {
    if (_isAccommodationStart) {
      return _buildAccommodationCard(context);
    }

    // 🔧 DEMO SYNC: Check if user has rated this in current session
    final double? userRating = DemoReviewStore.getLocationRating(activity.id);
    final bool hasUserRated = userRating != null;

    return InkWell(
      onTap: onCardTap,
      onLongPress: onCardLongPress,
      borderRadius: BorderRadius.circular(AppSizes.r16),
      child: Container(
        padding: const EdgeInsets.only(right: AppSizes.s8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.r16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 8,
              offset: const Offset(0, 3),
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
              width: 82,
              height: 104,
              borderRadius: AppSizes.r16,
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
                              fontSize: 14,
                              color: AppColorsExt.textDark,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
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
                    const SizedBox(height: AppSizes.s8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Color(0xFFFFC107),
                              size: 13,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${activity.rating?.toStringAsFixed(1) ?? "0.0"} (${_formatReviewCount(activity.reviewCount)})',
                              style: AppTextStylesExt.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        if (activity.price > 0)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_activity_outlined,
                                size: 12,
                                color: Color(0xFF6366F1),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                _formatPrice(activity.price),
                                style: AppTextStylesExt.bodySmall.copyWith(
                                  color: const Color(0xFF6366F1),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          )
                        else if (activity.isFree)
                          Text(
                            'Miễn phí',
                            style: AppTextStylesExt.bodySmall.copyWith(
                              color: const Color(0xFF10B981),
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                    // ── Tracking: badge "Đã ghé" hoặc nút "Tôi đã đến" ──────
                    if (trackingStatus != null) ...[
                      const SizedBox(height: AppSizes.s8),
                      _buildTrackingRow(),
                    ],
                    const SizedBox(height: AppSizes.s8),
                    _buildCardActions(hasUserRated, userRating),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardActions(bool hasUserRated, double? userRating) {
    // Backend data takes precedence; fall back to demo store when not loaded.
    final bool backendReviewed = hasReview == true;
    final bool showAsReviewed = backendReviewed || hasUserRated;

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _cardActionButton(
          icon: Icons.open_in_new_rounded,
          label: 'Xem chi ti\u1ebft \u0111\u1ecba \u0111i\u1ec3m',
          color: const Color(0xFF2563EB),
          onTap: onViewDetailTap ?? onCardLongPress,
        ),
        // Hi\u1ec7n n\u00fat khi \u0111\u00e3 gh\u00e9 th\u0103m ho\u1eb7c \u0111\u00e3 c\u00f3 review t\u1eeb backend
        if (_isVisited || backendReviewed)
          _cardActionButton(
            icon: backendReviewed
                ? Icons.visibility_rounded
                : (showAsReviewed
                    ? Icons.star_rounded
                    : Icons.rate_review_rounded),
            label: backendReviewed
                ? 'Xem \u0111\u00e1nh gi\u00e1'
                : (showAsReviewed
                    ? '\u0110\u00e3 \u0111\u00e1nh gi\u00e1 ${userRating?.toStringAsFixed(1) ?? ''}'
                    : isOpeningReview
                    ? '\u0110ang m\u1edf'
                    : '\u0110\u00e1nh gi\u00e1'),
            color: const Color(0xFF10B981),
            onTap: isOpeningReview ? null : onRateTap,
            isLoading: isOpeningReview,
          ),
      ],
    );
  }

  Widget _cardActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.20)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 13,
                height: 13,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              )
            else
              Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingRow() {
    final status = trackingStatus!.status;
    if (status == VisitStatus.visited) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 11,
                  color: Color(0xFF10B981),
                ),
                SizedBox(width: 4),
                Text(
                  'Đã đến nơi',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    if (status == VisitStatus.skipped) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFE53935).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.remove_circle_outline,
                  size: 11,
                  color: Color(0xFFE53935),
                ),
                SizedBox(width: 4),
                Text(
                  'Đã bỏ qua',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE53935),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    // notVisited → nút check-in thủ công
    return GestureDetector(
      onTap: isCheckingIn ? null : onCheckIn,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF2563EB).withValues(alpha: 0.25),
          ),
        ),
        child: isCheckingIn
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: Color(0xFF2563EB),
                ),
              )
            : const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 11,
                    color: Color(0xFF2563EB),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Tôi đã đến',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildAccommodationCard(BuildContext context) {
    return InkWell(
      onTap: onCardTap,
      borderRadius: BorderRadius.circular(AppSizes.r16),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.s16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(AppSizes.r16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.r12),
              ),
              child: const Icon(
                Icons.hotel_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSizes.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nơi ở & xuất phát',
                    style: AppTextStylesExt.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: AppSizes.s4),
                  Text(
                    activity.title,
                    style: AppTextStyles.heading2.copyWith(
                      fontSize: 15,
                      color: AppColorsExt.textDark,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (activity.address.isNotEmpty) ...[
                    const SizedBox(height: AppSizes.s4),
                    Text(
                      activity.address,
                      style: AppTextStylesExt.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallEditAction(IconData icon, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }

  Widget _buildTransitionChip() {
    final chip = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.s16,
        vertical: AppSizes.s8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.r24),
        border: Border.all(
          color: onDirectionTap != null
              ? AppColors.primary.withAlpha(80)
              : AppColorsExt.divider.withAlpha(100),
        ),
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
              nextTransportInfo ?? '10-20 phút di chuyển',
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
          Icon(
            Icons.directions,
            size: 16,
            color: onDirectionTap != null
                ? AppColors.primary
                : AppColorsExt.textHint,
          ),
        ],
      ),
    );

    if (onDirectionTap == null) return chip;

    return GestureDetector(onTap: onDirectionTap, child: chip);
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
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
