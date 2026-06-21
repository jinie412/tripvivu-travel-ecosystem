import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:travel_advisor_mobile/core/config/app_config.dart';
import 'package:travel_advisor_mobile/core/di/injection_container.dart';

import 'itinerary_detail_screen.dart';
import 'package:travel_advisor_mobile/features/itinerary/tracking/data/models/tracking_models.dart';
import 'package:travel_advisor_mobile/features/itinerary/tracking/presentation/cubit/tracking_cubit.dart';
import 'package:travel_advisor_mobile/features/itinerary/tracking/presentation/cubit/tracking_state.dart';

import 'package:travel_advisor_mobile/core/widgets/section_header.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_detail_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_day_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_activity_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/cubit/itinerary_cubit.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/cubit/itinerary_state.dart';
import 'package:travel_advisor_mobile/features/review/presentation/widgets/itinerary_rating_popup.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/widgets/short_itinerary_item.dart';
import 'package:travel_advisor_mobile/features/saved/data/datasources/favorite_remote_datasource.dart';

/// Chế độ thiết kế: true dùng dữ liệu mẫu, false dùng API.
const bool _useMockData = AppConfig.kUseMockData;

class ItinerarySummaryScreen extends StatefulWidget {
  final String itineraryId;

  const ItinerarySummaryScreen({super.key, required this.itineraryId});

  @override
  State<ItinerarySummaryScreen> createState() => _ItinerarySummaryScreenState();
}

class _ItinerarySummaryScreenState extends State<ItinerarySummaryScreen> {
  @override
  void initState() {
    super.initState();
    if (!_useMockData) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final cubit = context.read<ItineraryCubit>();
        final state = cubit.state;
        final alreadyLoaded =
            state is ItineraryLoaded &&
            state.selectedItinerary?.id == widget.itineraryId;
        if (!alreadyLoaded) {
          cubit.ensureItinerarySelected(widget.itineraryId);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ItinerarySummaryView(itineraryId: widget.itineraryId);
  }
}

class _ItinerarySummaryView extends StatelessWidget {
  final String itineraryId;
  const _ItinerarySummaryView({required this.itineraryId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ItineraryCubit, ItineraryState>(
      builder: (context, state) {
        if (_useMockData) {
          final itin = _generateMockData();
          return _buildContent(context, itin);
        }

        if (state is ItineraryLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is ItineraryError) {
          return Scaffold(body: Center(child: Text(state.message)));
        }
        if (state is ItineraryLoaded && state.selectedItinerary == null) {
          if (state.detailError != null) {
            return _buildDetailErrorScaffold(context);
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is! ItineraryLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final itin = state.selectedItinerary!;
        return _buildContent(context, itin);
      },
    );
  }

  Widget _buildContent(BuildContext context, ItineraryDetailEntity itin) {
    final now = DateTime.now();
    final dateFormatter = DateFormat('dd/MM');
    final dateRange =
        '${dateFormatter.format(itin.startDate)} - ${dateFormatter.format(itin.endDate)}, ${itin.startDate.year}';
    final trackingState = context.watch<TrackingCubit>().state;
    final costSnapshot = _buildCostSnapshot(itin, trackingState);
    final totalVisitCount = costSnapshot.totalVisitCount;
    final visitedVisitCount = costSnapshot.visitedCount;
    final canReview = _canReviewItinerary(itin, now);

    return Scaffold(
      backgroundColor: const Color(0xFFFBFDFF),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Color(0xFF1C1C1E),
              size: 16,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: Colors.white.withValues(alpha: 0.5),
              child: const Text(
                'Tóm tắt lịch trình',
                style: TextStyle(
                  color: Color(0xFF1C1C1E),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(1, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.edit_rounded,
                color: Color(0xFF2563EB),
                size: 20,
              ),
              onPressed: () => _showEditTitleDialog(context, itin),
            ),
          ),
          if (itin.isPublic)
            Container(
              margin: EdgeInsets.only(right: canReview ? 8 : 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(1, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  itin.isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: itin.isFavorite
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF2563EB),
                  size: 22,
                ),
                onPressed: () => _toggleFavorite(context, itin),
              ),
            ),
          if (canReview)
            Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(1, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.stars_rounded,
                  color: Color(0xFF10B981),
                  size: 24,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => ItineraryRatingPopup(
                      itineraryId: itin.id,
                      itineraryTitle: itin.title,
                      totalLocations: itin.totalLocations,
                      visitedLocations: itin.visitedLocations,
                    ),
                  );
                },
              ),
            ),
        ],

      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header với Glassmorphism Image Card
                _buildDestinationHeader(
                  context,
                  itin,
                  dateRange,
                  visitedVisitCount,
                  totalVisitCount,
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Tổng quan chuyến đi',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildStatsGrid(itin),

                      if (itin.visitedRestaurants.isNotEmpty) ...[
                        const SizedBox(height: 36),
                        const SectionHeader(title: 'Món ăn đã đặt'),
                        const SizedBox(height: 12),
                        _buildCulinarySection(itin),
                      ],

                      const SizedBox(height: 36),
                      _buildBudgetSection(itin, costSnapshot),

                      const SizedBox(height: 36),
                      const SectionHeader(title: 'Tổng quan theo ngày'),
                      const SizedBox(height: 12),
                      ...itin.days
                          .take(3)
                          .map(
                            (day) => ShortItineraryItem(
                              dayNumber: day.dayNumber,
                              date: DateFormat('dd/MM/yyyy').format(day.date),
                              title: _shortDayTitle(day),
                              icon: Icons.event_note_rounded,
                              onTap: () => _navigateToDetail(
                                context,
                                itin,
                                initialDay: day.dayNumber,
                              ),
                            ),
                          ),
                      if (itin.days.length > 3)
                        _buildViewAllDaysButton(context, itin),

                      if (itin.notes.isNotEmpty) ...[
                        const SizedBox(height: 36),
                        _buildNotesSection(itin.notes),
                      ],

                      const SizedBox(height: 120), // Spacing for bottom button
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Nút xem chi tiết ở dưới cùng (Floating effect)
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: _buildActionBtn(context, itin),
          ),
        ],
      ),
      );
  }

  Future<void> _toggleFavorite(
    BuildContext context,
    ItineraryDetailEntity itin,
  ) async {
    if (!itin.isPublic) {
      return;
    }

    final cubit = context.read<ItineraryCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final nextFavorite = !itin.isFavorite;

    cubit.setSelectedItineraryFavorite(nextFavorite);

    try {
      await sl<FavoriteRemoteDataSource>().setItineraryFavorite(
        itin.id,
        nextFavorite,
      );
      if (!context.mounted) return;
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            nextFavorite
                ? 'Đã lưu vào danh mục yêu thích'
                : 'Đã bỏ khỏi danh mục yêu thích',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      cubit.setSelectedItineraryFavorite(itin.isFavorite);
      if (!context.mounted) return;
      messenger.clearSnackBars();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Chưa thể cập nhật yêu thích, vui lòng thử lại'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildDestinationHeader(
    BuildContext context,
    ItineraryDetailEntity itin,
    String dateRange,
    int visitedVisitCount,
    int totalVisitCount,
  ) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.45,
      width: double.infinity,
      child: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=1000&q=80', // Hình ảnh biển Phú Quốc
              fit: BoxFit.cover,
            ),
          ),
          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.black.withValues(alpha: 0.1),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.2),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: const [0.0, 0.3, 0.6, 1.0],
                ),
              ),
            ),
          ),
          // Glass Card for Info
          Positioned(
            left: 20,
            right: 20,
            bottom: 30,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 14,
                                      color: Colors.blue.shade300,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'ĐIỂM ĐẾN',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.white.withValues(
                                          alpha: 0.7,
                                        ),
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  itin.destination,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  itin.title,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${_getStatusText(itin)} • $visitedVisitCount/$totalVisitCount địa điểm',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if ((itin.tripIntent ?? '')
                                    .trim()
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.18,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.18,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.local_offer_outlined,
                                          size: 13,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            'Chủ đề: ${itin.tripIntent!.trim()}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Material(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(18),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => _showEditTitleDialog(context, itin),
                              child: const SizedBox(
                                width: 48,
                                height: 48,
                                child: Icon(
                                  Icons.edit_outlined,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_month,
                            color: Colors.white.withValues(alpha: 0.6),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            dateRange,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canReviewItinerary(
    ItineraryDetailEntity itin,
    DateTime now,
  ) {
    final today = DateUtils.dateOnly(now);
    final endDate = DateUtils.dateOnly(itin.endDate);
    final status = itin.status.toUpperCase();
    final hasStarted =
        status == 'ONGOING' || status == 'COMPLETED' || itin.trackingActive;
    return !today.isBefore(endDate) && hasStarted;
  }

  void _showEditTitleDialog(BuildContext context, ItineraryDetailEntity itin) {
    final TextEditingController controller = TextEditingController(
      text: itin.title,
    );
    // Capture cubit và scaffoldMessenger trước khi showDialog,
    // vì context bên trong builder của dialog không thuộc subtree của BlocProvider.
    final cubit = context.read<ItineraryCubit>();
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Chỉnh sửa tên lịch trình',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Nhập tên lịch trình mới...',
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Hủy', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                Navigator.pop(dialogContext);
                cubit.updateItineraryTitle(itin.id, newTitle);
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Đang cập nhật tên lịch trình...'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Lưu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _getStatusText(ItineraryDetailEntity itin) {
    if (itin.status == 'COMPLETED') return 'Lịch trình kết thúc';
    if (itin.status == 'ONGOING') return 'Đang diễn ra';
    if (itin.status == 'UPCOMING') return 'Lịch trình sắp tới';
    if (itin.status == 'DRAFT') return 'Đang lên kế hoạch';
    return 'Lịch trình';
  }

  Widget _buildDetailErrorScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFDFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Color(0xFF1C1C1E),
              size: 16,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFEF4444),
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Không thể tải lịch trình',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1C1C1E),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Đã xảy ra lỗi khi tải chi tiết lịch trình.\nVui lòng kiểm tra kết nối mạng và thử lại.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => context
                      .read<ItineraryCubit>()
                      .ensureItinerarySelected(itineraryId),
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text(
                    'Thử lại',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6B7280),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Quay lại',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(ItineraryDetailEntity itin) {
    final hotelCount = _uniqueHotelCount(itin);
    final visitCount = _totalVisitCount(itin);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCardV2(
                label: 'Thời gian',
                value: '${itin.durationDays} ngày',
                icon: Icons.calendar_today_rounded,
                color: const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCardV2(
                label: 'Hoạt động',
                value: '$visitCount điểm',
                icon: Icons.explore_rounded,
                color: const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatCardV2(
                label: 'Chỗ ở',
                value: hotelCount > 0 ? '$hotelCount khách sạn' : 'Chưa chọn',
                icon: Icons.hotel_rounded,
                color: const Color(0xFFEC4899),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCardV2(
                label: 'Be/Grab/tự túc',
                value: itin.transportTurns > 0
                    ? '${itin.transportTurns} chặng'
                    : 'Theo lộ trình',
                icon: Icons.directions_car_filled_rounded,
                color: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBudgetSection(
    ItineraryDetailEntity itin,
    _CostSnapshot costSnapshot,
  ) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    final estimatedCost = itin.estimatedBudget > 0
        ? itin.estimatedBudget
        : costSnapshot.estimatedCost;
    final spentCost = costSnapshot.spentCost;
    final spentProgress = estimatedCost > 0
        ? (spentCost / estimatedCost).clamp(0.0, 1.0)
        : 0.0;

    return _buildBudgetSectionV2(
      itin: itin,
      formatter: formatter,
      estimatedCost: estimatedCost,
      spentCost: spentCost,
      spentProgress: spentProgress,
      costSnapshot: costSnapshot,
    );
  }

  Widget _buildBudgetSectionV2({
    required ItineraryDetailEntity itin,
    required NumberFormat formatter,
    required double estimatedCost,
    required double spentCost,
    required double spentProgress,
    required _CostSnapshot costSnapshot,
  }) {
    final estimatedLabel = estimatedCost > 0
        ? '${formatter.format(estimatedCost)} ${itin.currency}'
        : '\u0110ang c\u1eadp nh\u1eadt';
    final spentLabel = spentCost > 0
        ? '${formatter.format(spentCost)} ${itin.currency}'
        : '0 ${itin.currency}';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF334155).withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chi ph\u00ed chuy\u1ebfn \u0111i',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 20),
          _BudgetMetric(
            label:
                'Chi ph\u00ed \u01b0\u1edbc t\u00ednh to\u00e0n l\u1ecbch tr\u00ecnh',
            value: estimatedLabel,
            icon: Icons.receipt_long_rounded,
            color: const Color(0xFF10B981),
            fullWidth: true,
          ),
          if (itin.hotelCost > 0 || itin.transportCost > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _BudgetMetric(
                    label: itin.durationDays > 0
                        ? 'L\u01b0u tr\u00fa (${formatter.format(itin.hotelCost / itin.durationDays)} ${itin.currency}/ng\u00e0y)'
                        : 'L\u01b0u tr\u00fa',
                    value: itin.hotelCost > 0
                        ? '${formatter.format(itin.hotelCost)} ${itin.currency}'
                        : '\u0110ang c\u1eadp nh\u1eadt',
                    icon: Icons.hotel_rounded,
                    color: const Color(0xFF0F766E),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _BudgetMetric(
                    label: 'X\u0103ng xe/t\u1ef1 t\u00fac',
                    value: itin.transportCost > 0
                        ? '${formatter.format(itin.transportCost)} ${itin.currency}'
                        : '\u0110ang c\u1eadp nh\u1eadt',
                    icon: Icons.two_wheeler_rounded,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
            if (itin.rideHailingTransportCost > 0) ...[
              const SizedBox(height: 12),
              _BudgetMetric(
                label: 'Be/Grab tham kh\u1ea3o',
                value:
                    '${formatter.format(itin.rideHailingTransportCost)} ${itin.currency}',
                icon: Icons.local_taxi_rounded,
                color: const Color(0xFF7C3AED),
                fullWidth: true,
              ),
            ],
          ],
          const SizedBox(height: 18),
          if (estimatedCost > 0) ...[
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Chi ph\u00ed \u0111\u00e3 chi',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Text(
                    spentLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFB45309),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Stack(
              children: [
                Container(
                  height: 12,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOut,
                      height: 12,
                      width: constraints.maxWidth * spentProgress,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${costSnapshot.visitedCount}/${costSnapshot.totalVisitCount} \u0111\u1ecba \u0111i\u1ec3m \u0111\u00e3 ghi nh\u1eadn chi ph\u00ed',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.all_inclusive_rounded,
                    size: 18,
                    color: Color(0xFF2563EB),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ch\u01b0a c\u00f3 d\u1eef li\u1ec7u chi ph\u00ed \u01b0\u1edbc t\u00ednh cho l\u1ecbch tr\u00ecnh n\u00e0y',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildViewAllDaysButton(
    BuildContext context,
    ItineraryDetailEntity itin,
  ) {
    return InkWell(
      onTap: () => _showAllDaysSheet(context, itin),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: Color(0xFF2563EB),
            ),
            const SizedBox(width: 8),
            Text(
              'Xem tất cả ${itin.days.length} ngày',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2563EB),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAllDaysSheet(BuildContext context, ItineraryDetailEntity itin) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Tất cả ngày trong lịch trình',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: itin.days
                        .map(
                          (day) => ShortItineraryItem(
                            dayNumber: day.dayNumber,
                            date: DateFormat('dd/MM/yyyy').format(day.date),
                            title: _shortDayTitle(day),
                            icon: Icons.event_note_rounded,
                            onTap: () {
                              Navigator.pop(sheetContext);
                              _navigateToDetail(
                                context,
                                itin,
                                initialDay: day.dayNumber,
                              );
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionBtn(BuildContext context, ItineraryDetailEntity itin) {
    final now = DateTime.now();
    // Logic xét trạng thái dựa trên thời gian thực
    final bool isFuture = now.isBefore(itin.startDate);

    String btnText = 'XEM CHI TIẾT LỊCH TRÌNH';
    Color btnColor = const Color(0xFF1E3A8A);
    IconData btnIcon = Icons.arrow_forward;
    void onPressed() => _navigateToDetail(context, itin);

    if (isFuture) {
      btnText = 'BẮT ĐẦU LỊCH TRÌNH';
      btnIcon = Icons.play_circle_outline_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: btnColor.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: btnColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              btnText,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(width: 8),
            Icon(btnIcon, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection(List<String> notes) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.tips_and_updates_rounded,
                  size: 20,
                  color: Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Ghi chú cho chuyến đi',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...notes.map(
            (note) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(
                      Icons.check_circle_outline,
                      size: 14,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      note,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF475569),
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCulinarySection(ItineraryDetailEntity itin) {
    final formatter = NumberFormat('#,###', 'vi_VN');

    // Tính tổng tất cả món ăn
    double grandTotal = 0;
    for (var restaurant in itin.visitedRestaurants) {
      for (var dish in restaurant.dishes) {
        grandTotal += dish.price * dish.quantity;
      }
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF1F5F9)),
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
          ...itin.visitedRestaurants.map((food) {
            return _CulinaryExpandableItem(food: food);
          }),
          // Dòng tổng cộng chung
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng cộng chi phí',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  '${formatter.format(grandTotal)} VNĐ',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ItineraryDetailEntity _generateMockData() {
    final now = DateTime.now();
    return ItineraryDetailEntity(
      id: 'mock_123',
      title: 'Kỳ nghỉ hè Phú Quốc 2024',
      destination: 'Phú Quốc',
      startDate: now.subtract(const Duration(days: 5)),
      endDate: now.subtract(const Duration(days: 1)), // Kết thúc ngày hôm qua
      status: 'COMPLETED', // Để kiểm tra trạng thái đánh giá
      durationDays: 4,
      activitiesCount: 12,
      hotelsCount: 1,
      transportTurns: 6,
      estimatedBudget: 8500000,
      spentBudget: 1200000,
      currency: 'VNĐ',
      days: [
        ItineraryDayEntity(
          dayNumber: 1,
          date: now.add(const Duration(days: 5)),
          locationsCount: 3,
          totalDuration: '8:00 - 20:00',
          dayBudget: 2000000,
          activities: [
            const ItineraryActivityEntity(
              id: 'a1',
              title: 'Check-in VinWonders Phú Quốc',
              startTime: '09:00',
              endTime: '12:00',
              locationName: 'VinWonders',
              address: 'Gành Dầu, Phú Quốc',
              imageUrl: '',
            ),
          ],
        ),
        ItineraryDayEntity(
          dayNumber: 2,
          date: now.add(const Duration(days: 6)),
          locationsCount: 4,
          totalDuration: '07:30 - 21:00',
          dayBudget: 1500000,
          activities: [
            const ItineraryActivityEntity(
              id: 'a2',
              title: 'Lặn ngắm san hô Hòn Móng Tay',
              startTime: '08:00',
              endTime: '11:00',
              locationName: 'Hòn Móng Tay',
              address: 'Phía Nam Đảo',
              imageUrl: '',
            ),
          ],
        ),
      ],
      notes: [
        'Mang theo kem chống nắng và mũ rộng vành.',
        'Đừng quên mang bằng lái xe để thuê xe máy.',
        'Đặt trước vé Buffet ở VinWonders để được giá tốt.',
      ],
      visitedRestaurants: [
        const VisitedRestaurant(
          name: 'Bún Quậy Kiến Xây',
          imageUrl:
              'https://images.unsplash.com/photo-1582878826629-29b7adcontent1?w=200&q=80',
          dishes: [
            VisitedDish(name: 'Tô đặc biệt', price: 65000, quantity: 2),
            VisitedDish(name: 'Nước mía', price: 10000, quantity: 2),
          ],
        ),
        const VisitedRestaurant(
          name: 'Hải Sản Xin Chào',
          imageUrl:
              'https://images.unsplash.com/photo-1551733938-466a382CONTENT3?w=200&q=80',
          dishes: [
            VisitedDish(name: 'Tôm hùm nướng cốt', price: 1200000, quantity: 1),
            VisitedDish(name: 'Nghêu hấp sả', price: 120000, quantity: 1),
          ],
        ),
      ],
    );
  }

  void _navigateToDetail(
    BuildContext context,
    ItineraryDetailEntity itin, {
    int initialDay = 1,
  }) {
    final itinCubit = context.read<ItineraryCubit>();
    final trackingCubit = context.read<TrackingCubit>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: itinCubit),
            BlocProvider.value(value: trackingCubit),
          ],
          child: ItineraryDetailScreen(
            itineraryId: itin.id,
            initialDetail: itin,
            initialDay: initialDay,
          ),
        ),
      ),
    );
  }

  bool _isHotelStart(ItineraryActivityEntity activity) {
    final category = (activity.category ?? '').toLowerCase();
    final title = activity.title.toLowerCase();
    final isHotelLike =
        category.contains('lưu trú') ||
        category.contains('khách sạn') ||
        category.contains('accommodation') ||
        category.contains('hotel') ||
        category.contains('resort') ||
        category.contains('homestay') ||
        title.contains('hotel') ||
        title.contains('khách sạn') ||
        title.contains('resort') ||
        title.contains('homestay') ||
        title.contains('villa');
    final sameTime = activity.startTime == activity.endTime;
    return isHotelLike && sameTime;
  }

  List<ItineraryActivityEntity> _visitActivities(ItineraryDayEntity day) {
    return day.activities
        .where((activity) => !_isHotelStart(activity))
        .toList();
  }

  String _shortDayTitle(ItineraryDayEntity day) {
    final visitCount = _visitActivities(day).length;
    if (visitCount == 0) return 'Chưa có điểm tham quan';
    final budget = day.dayBudget > 0 ? day.dayBudget : _dayActivityCost(day);
    if (budget <= 0) return '$visitCount điểm tham quan';
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '$visitCount điểm • ${formatter.format(budget)} ${day.currency}';
  }

  int _uniqueHotelCount(ItineraryDetailEntity itin) {
    final hotels = <String>{};
    for (final day in itin.days) {
      for (final activity in day.activities.where(_isHotelStart)) {
        final key = activity.placeId?.isNotEmpty == true
            ? activity.placeId!
            : activity.title.toLowerCase();
        hotels.add(key);
      }
    }
    if (hotels.isNotEmpty) return hotels.length;
    return itin.hotelsCount > 0 ? 1 : 0;
  }

  _CostSnapshot _buildCostSnapshot(
    ItineraryDetailEntity itin,
    TrackingState trackingState,
  ) {
    final visits = itin.days.expand(_visitActivities).toList();
    final trackingPlaces = trackingState.itineraryId == itin.id
        ? trackingState.places
        : const <TrackingPlaceStatus>[];
    final hasTrackingPlaces = trackingPlaces.isNotEmpty;
    final visitedByDetailId = {
      for (final place in trackingPlaces)
        if (place.status == VisitStatus.visited) place.itineraryDetailId,
    };
    final visitedByPlaceId = {
      for (final place in trackingPlaces)
        if (place.status == VisitStatus.visited && place.placeId != null)
          place.placeId!,
    };

    bool isVisited(ItineraryActivityEntity activity) {
      final backendVisited = activity.status == ActivityStatus.daDi;
      if (hasTrackingPlaces) {
        if (visitedByDetailId.contains(activity.id)) return true;
        final placeId = activity.placeId;
        if (placeId != null && visitedByPlaceId.contains(placeId)) return true;
      }
      return backendVisited;
    }

    final visitedActivities = visits.where(isVisited).toList();
    final fallbackVisitedCount =
        !hasTrackingPlaces &&
            visitedActivities.isEmpty &&
            itin.visitedLocations > 0
        ? itin.visitedLocations.clamp(0, visits.length).toInt()
        : visitedActivities.length;
    final activityEstimatedCost = visits.fold<double>(
      0,
      (sum, activity) => sum + activity.price,
    );
    final estimatedCost = itin.estimatedBudget > 0
        ? itin.estimatedBudget
        : activityEstimatedCost;
    final spentCost = visitedActivities.fold<double>(
      0,
      (sum, activity) => sum + activity.price,
    );
    final apiVisitedCount = visits.isNotEmpty
        ? itin.visitedLocations.clamp(0, visits.length).toInt()
        : itin.visitedLocations;

    return _CostSnapshot(
      totalVisitCount: visits.isNotEmpty
          ? visits.length
          : _totalVisitCount(itin),
      visitedCount: fallbackVisitedCount > itin.visitedLocations
          ? fallbackVisitedCount
          : apiVisitedCount,
      estimatedCost: estimatedCost,
      spentCost: spentCost > itin.spentBudget ? spentCost : itin.spentBudget,
    );
  }

  int _totalVisitCount(ItineraryDetailEntity itin) {
    final count = itin.days.fold<int>(
      0,
      (sum, day) => sum + _visitActivities(day).length,
    );
    if (count > 0) return count;
    if (itin.totalLocations > 0) return itin.totalLocations;
    return itin.activitiesCount;
  }

  double _dayActivityCost(ItineraryDayEntity day) {
    return _visitActivities(
      day,
    ).fold<double>(0, (sum, activity) => sum + activity.price);
  }
}

class _CostSnapshot {
  final int totalVisitCount;
  final int visitedCount;
  final double estimatedCost;
  final double spentCost;

  const _CostSnapshot({
    required this.totalVisitCount,
    required this.visitedCount,
    required this.estimatedCost,
    required this.spentCost,
  });
}

class _BudgetMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool fullWidth;

  const _BudgetMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
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

class _StatCardV2 extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCardV2({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CulinaryExpandableItem extends StatefulWidget {
  final VisitedRestaurant food;
  const _CulinaryExpandableItem({required this.food});

  @override
  State<_CulinaryExpandableItem> createState() =>
      _CulinaryExpandableItemState();
}

class _CulinaryExpandableItemState extends State<_CulinaryExpandableItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    double subTotal = 0;
    for (var dish in widget.food.dishes) {
      subTotal += dish.price * dish.quantity;
    }

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.restaurant_menu_rounded,
                    color: Color(0xFF2563EB),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.food.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            '${widget.food.dishes.length} món',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: const BoxDecoration(
                              color: Color(0xFFCBD5E1),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${formatter.format(subTotal)} đ',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_up : Icons.chevron_right,
                  color: const Color(0xFFCBD5E1),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: widget.food.dishes.map((dish) {
                final formatter = NumberFormat('#,###', 'vi_VN');
                return Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dish.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                      Text(
                        '${formatter.format(dish.price)} đ x ${dish.quantity}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Divider(height: 1, color: Color(0xFFF1F5F9)),
        ),
      ],
    );
  }
}
