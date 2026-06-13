import 'dart:async';

import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_entity.dart';
import 'package:travel_advisor_mobile/features/review/presentation/screens/rate_itinerary_screen.dart';

/// Reusable itinerary list card.
///
/// Shows the trip name, date badge, cost, visited-place progress, optional
/// start toggle, and the place-image slideshow returned by the list API.
class ItineraryCard extends StatelessWidget {
  final ItineraryEntity item;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onStartToggle;

  const ItineraryCard({
    super.key,
    required this.item,
    this.onEdit,
    this.onDelete,
    this.onTap,
    this.onStartToggle,
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
                // ── Ảnh slideshow + badge ngày ───────────────────────────────
                SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _PlaceImageSlideshow(
                        images: item.placeImages,
                        placeholderColor: item.placeholderColor,
                      ),
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
                            child: Text(
                              'ĐÃ KẾT THÚC',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      if (_shouldShowStart(item))
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            height: 32,
                            padding: const EdgeInsets.only(left: 12, right: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  item.status == ItineraryStatus.ongoing ? 'ĐANG DIỄN RA' : 'BẮT ĐẦU LỊCH TRÌNH',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: item.status == ItineraryStatus.ongoing ? const Color(0xFF2563EB) : const Color(0xFF4B5563),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Transform.scale(
                                  scale: 0.65,
                                  child: Switch(
                                    value: item.status == ItineraryStatus.ongoing,
                                    onChanged: onStartToggle,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    activeThumbColor: Colors.white,
                                    activeTrackColor: const Color(0xFF2563EB),
                                    inactiveThumbColor: Colors.white,
                                    inactiveTrackColor: const Color(0xFFD1D5DB),
                                    trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                                  ),
                                ),
                              ],
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

  Widget _buildProgressBar() {
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
        // Số lượng địa điểm
        Text(
          '${item.visitedLocations}/${item.totalLocations} địa điểm',
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
    if (cost >= 1000000000) {
      final val = cost / 1000000000;
      final display = val == val.truncateToDouble()
          ? val.toInt().toString()
          : NumberFormat('#,##0.#', 'vi_VN').format(val);
      return '$display tỷ $currency';
    }
    if (cost >= 1000000) {
      final val = cost / 1000000;
      final display = val == val.truncateToDouble()
          ? val.toInt().toString()
          : NumberFormat('#,##0.#', 'vi_VN').format(val);
      return '$display triệu $currency';
    }
    return '${NumberFormat('#,###', 'vi_VN').format(cost)} $currency';
  }

  bool _shouldShowStart(ItineraryEntity item) {
    if (item.status == ItineraryStatus.completed) return false;
    if (item.status == ItineraryStatus.ongoing) return true;
    if (item.startDate == null) return false;

    final today = DateTime.now();
    final start = item.startDate!;

    return start.year == today.year && start.month == today.month && start.day == today.day;
  }
}

/// Renders the place images returned by `place_images` in the list API.
///
/// Behavior:
/// - 0 images: fallback to the placeholder color.
/// - 1 image: static image, no timer and no dots.
/// - 2+ images: auto-advancing PageView with a dot indicator.
class _PlaceImageSlideshow extends StatefulWidget {
  final List<String> images;
  final int placeholderColor;

  const _PlaceImageSlideshow({
    required this.images,
    required this.placeholderColor,
  });

  @override
  State<_PlaceImageSlideshow> createState() => _PlaceImageSlideshowState();
}

class _PlaceImageSlideshowState extends State<_PlaceImageSlideshow> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    if (widget.images.length <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final next = (_currentPage + 1) % widget.images.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    final placeholder = Container(color: Color(widget.placeholderColor));

    if (images.isEmpty) return placeholder;

    if (images.length == 1) {
      return CachedNetworkImage(
        imageUrl: images[0],
        fit: BoxFit.cover,
        placeholder: (_, _) => placeholder,
        errorWidget: (_, _, _) => placeholder,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: images.length,
          onPageChanged: (i) => setState(() => _currentPage = i),
          itemBuilder: (_, i) => CachedNetworkImage(
            imageUrl: images[i],
            fit: BoxFit.cover,
            placeholder: (_, _) => placeholder,
            errorWidget: (_, _, _) => placeholder,
          ),
        ),
        Positioned(
          bottom: 10,
          right: 10,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(images.length, (i) {
              final isActive = i == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(left: 4),
                width: isActive ? 8 : 5,
                height: isActive ? 8 : 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.45),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
