import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:travel_advisor_mobile/core/config/app_config.dart';
import 'package:travel_advisor_mobile/core/constants/app_colors.dart';
import 'package:travel_advisor_mobile/core/constants/cost_ui_labels.dart';
import 'package:travel_advisor_mobile/core/di/injection_container.dart';

import 'itinerary_detail_screen.dart';
import 'package:travel_advisor_mobile/features/itinerary/tracking/data/models/tracking_models.dart';
import 'package:travel_advisor_mobile/features/itinerary/tracking/presentation/cubit/tracking_cubit.dart';
import 'package:travel_advisor_mobile/features/itinerary/tracking/presentation/cubit/tracking_state.dart';

import 'package:travel_advisor_mobile/core/widgets/section_header.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/incurred_cost_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_detail_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_day_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_activity_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/repositories/itinerary_repository.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/cubit/itinerary_cubit.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/cubit/itinerary_state.dart';
import 'package:travel_advisor_mobile/features/review/presentation/widgets/itinerary_rating_popup.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/widgets/short_itinerary_item.dart';
import 'package:travel_advisor_mobile/features/saved/data/datasources/favorite_remote_datasource.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/widgets/public_visibility_switch.dart';
import 'package:travel_advisor_mobile/features/food/presentation/screens/food_menu_screen.dart';
import 'package:travel_advisor_mobile/features/food/presentation/widgets/pre_order_popup.dart';
import 'package:travel_advisor_mobile/features/itinerary/tracking/tracking_config.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/screens/incurred_costs_screen.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/utils/day_cost_calculator.dart';
import 'package:travel_advisor_mobile/features/place/presentation/cubit/place_detail_cubit.dart';
import 'package:travel_advisor_mobile/features/place/presentation/screens/place_detail_screen.dart';

/// Chế độ thiết kế: true dùng dữ liệu mẫu, false dùng API.
const bool _useMockData = AppConfig.kUseMockData;

class ItinerarySummaryScreen extends StatefulWidget {
  final String itineraryId;
  final String? initialVisitDate;
  final bool autoOpenDetail;

  const ItinerarySummaryScreen({
    super.key,
    required this.itineraryId,
    this.initialVisitDate,
    this.autoOpenDetail = false,
  });

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
        if (alreadyLoaded) {
          cubit.refreshDetail(widget.itineraryId);
        } else {
          cubit.ensureItinerarySelected(widget.itineraryId);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Reuse the global TrackingCubit if already provided (e.g. from home screen),
    // so food proximity events propagate here without spawning a duplicate tracker.
    TrackingCubit? existingCubit;
    try {
      existingCubit = context.read<TrackingCubit>();
    } catch (_) {}

    final view = _ItinerarySummaryView(
      itineraryId: widget.itineraryId,
      initialVisitDate: widget.initialVisitDate,
      autoOpenDetail: widget.autoOpenDetail,
    );
    if (existingCubit != null) return view;
    return BlocProvider<TrackingCubit>(
      create: (_) => sl<TrackingCubit>(),
      child: view,
    );
  }
}

class _ItinerarySummaryView extends StatefulWidget {
  final String itineraryId;
  final String? initialVisitDate;
  final bool autoOpenDetail;

  const _ItinerarySummaryView({
    required this.itineraryId,
    this.initialVisitDate,
    this.autoOpenDetail = false,
  });

  @override
  State<_ItinerarySummaryView> createState() => _ItinerarySummaryViewState();
}

class _ItinerarySummaryViewState extends State<_ItinerarySummaryView> {
  bool _didAutoOpenDetail = false;
  String? _costBreakdownItinId;
  Future<CostBreakdownEntity>? _costBreakdownFuture;

  /// Nguồn số liệu duy nhất cho card "Quản lý chi phí" — cùng API
  /// `getCostBreakdown()` mà [IncurredCostsScreen] dùng, để tránh có 2 công
  /// thức tính chi phí ước tính lệch nhau giữa 2 màn.
  Future<CostBreakdownEntity> _ensureCostBreakdown(String itineraryId) {
    if (_costBreakdownItinId != itineraryId || _costBreakdownFuture == null) {
      _costBreakdownItinId = itineraryId;
      _costBreakdownFuture = sl<ItineraryRepository>().getCostBreakdown(
        itineraryId,
      );
    }
    return _costBreakdownFuture!;
  }

  void _refreshCostBreakdown(String itineraryId) {
    setState(() {
      _costBreakdownItinId = itineraryId;
      _costBreakdownFuture = sl<ItineraryRepository>().getCostBreakdown(
        itineraryId,
      );
    });
  }

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
        _maybeAutoOpenDetail(context, itin);
        return _buildContent(context, itin);
      },
    );
  }

  void _maybeAutoOpenDetail(BuildContext context, ItineraryDetailEntity itin) {
    if (!widget.autoOpenDetail || _didAutoOpenDetail) return;
    _didAutoOpenDetail = true;
    final initialDay = _dayForVisitDate(itin, widget.initialVisitDate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      _navigateToDetail(context, itin, initialDay: initialDay);
    });
  }

  int _dayForVisitDate(ItineraryDetailEntity itin, String? visitDate) {
    if (visitDate == null || visitDate.isEmpty) return 1;
    for (final day in itin.days) {
      final ymd =
          '${day.date.year.toString().padLeft(4, '0')}-${day.date.month.toString().padLeft(2, '0')}-${day.date.day.toString().padLeft(2, '0')}';
      if (ymd == visitDate) return day.dayNumber;
    }
    return 1;
  }

  void _showFoodProximityPopup(BuildContext ctx, TrackingState state) {
    if (ModalRoute.of(ctx)?.isCurrent != true) return;
    final name = state.nearbyRestaurantName ?? 'Quán ăn gần đây';
    final detailId = state.nearbyRestaurantDetailId ?? '';
    final placeId = state.nearbyRestaurantPlaceId ?? '';
    if (!ctx.read<TrackingCubit>().claimNearbyRestaurantPopup(detailId)) {
      return;
    }
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PreOrderPopup(
        title: 'Quán ăn gần bạn!',
        message:
            'Bạn đang trong bán kính ${TrackingConfig.foodProximityKm.toInt()} km. Đặt trước để không phải chờ?',
        restaurantName: name,
        estimatedWaitMinutes: 15,
        rating: 0,
        reviewCount: 0,
        onOrderTap: () {
          Navigator.pop(ctx);
          ctx.read<TrackingCubit>().dismissNearbyRestaurant();
          Navigator.push(
            ctx,
            MaterialPageRoute(
              builder: (_) => FoodMenuScreen(
                placeId: placeId,
                restaurantName: name,
                itineraryDetailId: detailId,
              ),
            ),
          );
        },
        onSkipTap: () {
          Navigator.pop(ctx);
          ctx.read<TrackingCubit>().dismissNearbyRestaurant();
        },
      ),
    ).then((_) {
      if (ctx.mounted) ctx.read<TrackingCubit>().dismissNearbyRestaurant();
    });
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
    final canShare = _canShareItinerary(itin);

    return BlocListener<TrackingCubit, TrackingState>(
      listenWhen: (p, c) =>
          c.nearbyRestaurantName != null &&
          c.nearbyRestaurantName != p.nearbyRestaurantName,
      listener: _showFoodProximityPopup,
      child: Scaffold(
        backgroundColor: AppColors.premiumBackground,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leadingWidth: 72,
          titleSpacing: 0,
          elevation: 0,
          leading: Container(
            margin: const EdgeInsets.only(left: 16),
            alignment: Alignment.center,
            child: _floatingCircleButton(
              Icons.arrow_back_ios_new,
              () => Navigator.pop(context),
            ),
          ),
          title: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                color: Colors.black.withAlpha(120),
                child: const Text(
                  'Tóm tắt lịch trình',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          centerTitle: true,
          actions: [
            if (canShare)
              Container(
                margin: EdgeInsets.only(
                  right: itin.isPublic || canReview ? 8 : 16,
                ),
                alignment: Alignment.center,
                child: _floatingCircleButton(
                  Icons.share_outlined,
                  () => _showShareSheet(context, itin),
                ),
              ),
            if (itin.isPublic)
              Container(
                margin: EdgeInsets.only(right: canReview ? 8 : 16),
                alignment: Alignment.center,
                child: _floatingCircleButton(
                  itin.isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  () => _toggleFavorite(context, itin),
                  iconColor: itin.isFavorite
                      ? const Color(0xFFEF4444)
                      : Colors.white,
                ),
              ),
            if (canReview)
              Container(
                margin: const EdgeInsets.only(right: 16),
                alignment: Alignment.center,
                child: _floatingCircleButton(Icons.stars_rounded, () {
                  showDialog(
                    context: context,
                    builder: (_) => ItineraryRatingPopup(
                      itineraryId: itin.id,
                      itineraryTitle: itin.title,
                      totalLocations: totalVisitCount,
                      visitedLocations: visitedVisitCount,
                    ),
                  );
                }, iconColor: const Color(0xFF10B981)),
              ),
          ],
        ),
        body: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async {
                await context.read<ItineraryCubit>().refreshDetail(itin.id);
                if (mounted) _refreshCostBreakdown(itin.id);
              },
              child: SingleChildScrollView(
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
                                  color: AppColors.premiumBlue,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Tổng quan chuyến đi',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.premiumNavy,
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
                          const SectionHeader(
                            title: CostUiLabels.managementTitle,
                          ),
                          const SizedBox(height: 16),
                          _buildExpenseManagementCard(context, itin),

                          const SizedBox(height: 36),
                          const SectionHeader(title: 'Tổng quan theo ngày'),
                          const SizedBox(height: 12),
                          _buildHotelOverviewRow(itin),
                          _buildTransportOverviewRow(itin),
                          _buildDayOverviewNote(itin),
                          ...itin.days
                              .take(3)
                              .map<Widget>(
                                (day) => _buildShortItineraryItem(
                                  context,
                                  itin,
                                  day,
                                ),
                              ),
                          if (itin.days.length > 3)
                            _buildViewAllDaysButton(context, itin),

                          if (itin.notes.isNotEmpty) ...[
                            const SizedBox(height: 36),
                            _buildNotesSection(itin.notes),
                          ],

                          const SizedBox(
                            height: 120,
                          ), // Spacing for bottom button
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Nút xem chi tiết ở dưới cùng (Floating effect)
            Positioned(
              bottom: 16,
              left: 20,
              right: 20,
              child: _buildActionBtn(context, itin),
            ),
          ],
        ),
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

  void _showShareSheet(BuildContext context, ItineraryDetailEntity itin) {
    final cubit = context.read<ItineraryCubit>();
    final messenger = ScaffoldMessenger.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      enableDrag: false,
      builder: (_) => _ItineraryShareSheet(
        itinerary: itin,
        cubit: cubit,
        messenger: messenger,
      ),
    );
  }

  Future<void> _confirmVisibilityChange(
    BuildContext context,
    ItineraryDetailEntity itin,
    bool nextValue,
  ) async {
    if (nextValue == itin.isPublic) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          nextValue ? 'Công khai lịch trình?' : 'Chuyển về riêng tư?',
        ),
        content: Text(
          nextValue
              ? 'Lịch trình sẽ hiển thị trong khu vực khám phá công khai.'
              : 'Người khác sẽ không còn thấy lịch trình này trong khu vực công khai.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await context.read<ItineraryCubit>().toggleVisibility(itin.id, nextValue);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextValue
                ? 'Đã công khai lịch trình'
                : 'Đã chuyển lịch trình về riêng tư',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể cập nhật trạng thái công khai'),
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
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=1000&q=80',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black.withValues(alpha: 0.65),
              Colors.black.withValues(alpha: 0.20),
              Colors.black.withValues(alpha: 0.45),
            ],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: MediaQuery.of(context).padding.top + kToolbarHeight + 12,
          bottom: 32,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          'ĐIỂM ĐẾN',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                      if (itin.isOwner)
                        PublicVisibilitySwitch(
                          value: itin.isPublic,
                          dark: true,
                          borderless: true,
                          compact: true,
                          onChanged: (value) =>
                              _confirmVisibilityChange(context, itin, value),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    itin.destination,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: itin.isOwner
                        ? () => _showEditTitleDialog(context, itin)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              itin.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.95),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (itin.isOwner) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.edit_rounded,
                              size: 16,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _summaryInfoPill(
                        Icons.route_rounded,
                        '$visitedVisitCount/$totalVisitCount địa điểm',
                      ),
                      _summaryInfoPill(
                        Icons.calendar_month_rounded,
                        _formatFullDateRange(itin.startDate, itin.endDate),
                      ),
                      if ((itin.tripIntent ?? '').trim().isNotEmpty)
                        _summaryInfoPill(
                          Icons.local_offer_outlined,
                          itin.tripIntent!.trim(),
                        ),
                    ],
                  ),
                  if (itin.members.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildMembersRow(itin),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Dãy avatar xếp chồng của tất cả thành viên (chủ lịch trình đứng đầu).
  Widget _buildMembersRow(ItineraryDetailEntity itin) {
    const double avatarSize = 32;
    const double overlapStep = 22;
    const int maxVisible = 5;

    final members = itin.members;
    final visible = members.take(maxVisible).toList();
    final extraCount = members.length - visible.length;
    final circleCount = visible.length + (extraCount > 0 ? 1 : 0);
    final stackWidth = avatarSize + overlapStep * (circleCount - 1);

    return Row(
      children: [
        SizedBox(
          width: stackWidth,
          height: avatarSize,
          child: Stack(
            children: [
              for (var i = 0; i < visible.length; i++)
                Positioned(
                  left: overlapStep * i,
                  child: _memberAvatar(visible[i], avatarSize),
                ),
              if (extraCount > 0)
                Positioned(
                  left: overlapStep * visible.length,
                  child: Container(
                    width: avatarSize,
                    height: avatarSize,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.55),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.9),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      '+$extraCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            members.length == 1
                ? '1 thành viên'
                : '${members.length} thành viên đồng hành',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _memberAvatar(ItineraryMemberEntity member, double size) {
    final name = member.fullName.trim();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: member.isOwner ? const Color(0xFF2563EB) : const Color(0xFF0F766E),
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.9),
          width: 1.5,
        ),
      ),
      child: ClipOval(
        child: member.avatarUrl.isNotEmpty
            ? Image.network(
                member.avatarUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                // Avatar nhỏ — giải mã đúng kích thước hiển thị
                cacheWidth: (size * 3).ceil(),
                errorBuilder: (_, _, _) => fallback,
              )
            : fallback,
      ),
    );
  }

  Widget _summaryInfoPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.95),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatFullDateRange(DateTime start, DateTime end) {
    if (start.year == end.year) {
      if (start.month == end.month) {
        if (start.day == end.day) {
          return '${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')}, ${start.year}';
        }
        return '${start.day.toString().padLeft(2, '0')}–${end.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')}, ${start.year}';
      }
      return '${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')} – ${end.day.toString().padLeft(2, '0')}/${end.month.toString().padLeft(2, '0')}, ${start.year}';
    }
    return '${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')}/${start.year} – ${end.day.toString().padLeft(2, '0')}/${end.month.toString().padLeft(2, '0')}/${end.year}';
  }

  Widget _floatingCircleButton(
    IconData icon,
    VoidCallback onTap, {
    bool active = false,
    Color? iconColor,
  }) {
    return Material(
      color: active
          ? AppColors.primary.withAlpha(220)
          : Colors.black.withAlpha(120),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 18, color: iconColor ?? Colors.white),
        ),
      ),
    );
  }

  /// Chỉ chủ lịch trình mới được chia sẻ và chỉ khi lịch trình
  /// đang ở trạng thái PENDING hoặc ONGOING.
  bool _canShareItinerary(ItineraryDetailEntity itin) {
    if (!itin.isOwner) return false;
    final status = itin.status.toUpperCase();
    return status == 'PENDING' || status == 'ONGOING';
  }

  bool _canReviewItinerary(ItineraryDetailEntity itin, DateTime now) {
    if (!itin.isOwner) return false;
    final today = DateUtils.dateOnly(now);
    final endDate = DateUtils.dateOnly(itin.endDate);
    final status = itin.status.toUpperCase();
    final hasStarted =
        status == 'ONGOING' ||
        status == 'COMPLETED' ||
        status == 'UNCOMPLETED' ||
        itin.trackingActive;
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
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Chỉnh sửa tên lịch trình',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: controller,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
                decoration: InputDecoration(
                  hintText: 'Nhập tên mới...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF2563EB),
                      width: 2,
                    ),
                  ),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Hủy',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
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
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Lưu',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailErrorScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFDFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leadingWidth: 72,
        titleSpacing: 0,
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
                      .ensureItinerarySelected(widget.itineraryId),
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

  Widget _buildShortItineraryItem(
    BuildContext context,
    ItineraryDetailEntity itin,
    ItineraryDayEntity day, {
    bool isFromSheet = false,
  }) {
    final breakdown = DayCostCalculator.computeDaily(
      day: day,
      adultCount: itin.adultCount,
      childCount: itin.childCount,
      childPriceRatio: itin.childPriceRatio,
    );
    final stats = DayCostCalculator.travelStats(day);
    final formatter = NumberFormat('#,###', 'vi_VN');

    String? hoursText(int minutes) {
      if (minutes <= 0) return null;
      final hours = minutes / 60;
      return '${hours.toStringAsFixed(hours.truncateToDouble() == hours ? 0 : 1)} giờ';
    }

    return ShortItineraryItem(
      dayNumber: day.dayNumber,
      date: DateFormat('dd/MM/yyyy').format(day.date),
      totalCostText: "${formatter.format(breakdown.total)}đ",
      locationCount: DayCostCalculator.visitActivities(day).length,
      distanceKmText: stats.distanceKm > 0
          ? '${stats.distanceKm.toStringAsFixed(1)} km'
          : null,
      sightseeingTimeText: hoursText(stats.sightseeingMinutes) != null
          ? '${hoursText(stats.sightseeingMinutes)} tham quan'
          : null,
      travelTimeText: hoursText(stats.travelMinutes) != null
          ? '${hoursText(stats.travelMinutes)} di chuyển'
          : null,
      icon: Icons.event_note_rounded,
      onTap: () {
        if (isFromSheet) {
          Navigator.pop(context);
        }
        _navigateToDetail(context, itin, initialDay: day.dayNumber);
      },
    );
  }

  /// Ghi chú DUY NHẤT cho cả danh sách ngày bên dưới — thay vì lặp lại trên
  /// từng card (khó đọc khi cuộn nhiều ngày).
  Widget _buildDayOverviewNote(ItineraryDetailEntity itin) {
    final peopleLabel = itin.childCount > 0
        ? '${itin.adultCount} người lớn, ${itin.childCount} trẻ em'
        : '${itin.adultCount} người lớn';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        'Giá mỗi ngày dưới đây gồm tham quan + ăn uống (chưa gồm khách sạn, xăng xe), tính cho $peopleLabel.',
        style: const TextStyle(
          fontSize: 11.5,
          fontStyle: FontStyle.italic,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }

  /// Khách sạn hiển thị ở đây là TỔNG CẢ CHUYẾN (không chia theo ngày) — đặt
  /// ngay dưới tiêu đề "Tổng quan theo ngày", trên danh sách ngày, để người
  /// dùng hiểu khách sạn là 1 khoản riêng cho cả chuyến, còn các ngày bên
  /// dưới chỉ là tham quan + ăn uống + di chuyển của riêng ngày đó.
  Widget _buildHotelOverviewRow(ItineraryDetailEntity itin) {
    final hotelActivity = _hotelActivity(itin);
    final hotelName = hotelActivity == null
        ? null
        : (hotelActivity.locationName.isNotEmpty
              ? hotelActivity.locationName
              : hotelActivity.title);
    // Luôn tối thiểu 1 đêm, kể cả chuyến 1 ngày — mọi lịch trình đều bắt
    // buộc có 1 khoản khách sạn thật (khớp backend _hotel_total_cost).
    final nightCount = itin.durationDays > 1 ? itin.durationDays - 1 : 1;
    // Trẻ em tính theo childPriceRatio (khớp estimatedCostForGroup/Sổ chi
    // tiêu) — trước đây nhân theo TỔNG số người (trẻ em tính đủ 100% giá
    // khách sạn), khiến "card ngày (không gồm khách sạn) + card khách sạn"
    // luôn CAO HƠN "chi phí chưa dự trù" khi có trẻ em trong đoàn.
    final totalHotelCost =
        itin.hotelCost * itin.adultCount +
        itin.hotelCost * itin.childPriceRatio * itin.childCount;
    if (hotelName == null || totalHotelCost <= 0) {
      return const SizedBox.shrink();
    }
    final pricePerNightPerPerson = nightCount > 0
        ? itin.hotelCost / nightCount
        : itin.hotelCost;
    final formatter = NumberFormat('#,###', 'vi_VN');

    // Khách sạn luôn nằm ở ngày 1 (nhận phòng cuối ngày 1, xem
    // getItineraryDetail backend) — bấm vào card này mở thẳng Chi tiết lịch
    // trình ở ngày 1, nơi khách sạn hiện ra cuối timeline và có thể bấm xem
    // tiếp chi tiết địa điểm — trước đây card này không bấm được gì cả.
    return InkWell(
      onTap: () => _navigateToDetail(context, itin, initialDay: 1),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF3F4F6)),
        ),
        // Tên khách sạn xuống dòng riêng thay vì chia đôi hàng ngang với cột
        // giá — tên dài + "N đêm • giá/đêm/người" ép chung 1 hàng trước đây
        // khiến tên khách sạn bị bóp/che gần hết.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.hotel_rounded,
                    color: Color(0xFFEC4899),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Khách sạn (cả chuyến)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                ),
                Text(
                  '${formatter.format(totalHotelCost)}đ',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              hotelName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 2),
            Text(
              nightCount > 0
                  ? '$nightCount đêm • ${formatter.format(pricePerNightPerPerson)}đ/đêm/người'
                  : '${formatter.format(pricePerNightPerPerson)}đ/đêm/người',
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
            ),
            if (hotelActivity != null) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _openHotelPlaceDetail(hotelActivity),
                borderRadius: BorderRadius.circular(999),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.open_in_new_rounded,
                      size: 13,
                      color: Color(0xFF2563EB),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Xem chi tiết địa điểm',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Xăng xe hiển thị ở đây là TỔNG CẢ CHUYẾN, đặt ngay dưới khách sạn — cùng
  /// lý do: không thuộc riêng ngày nào, các ngày bên dưới chỉ còn tham quan +
  /// ăn uống. KHÁC khách sạn ở chỗ: itin.transportCost đã là tổng CẢ NHÓM sẵn
  /// (tính theo số xe cần dùng, xem backend estimateSelfDriveTransportCost),
  /// nên KHÔNG nhân thêm theo adultCount/childCount như _buildHotelOverviewRow
  /// — nhân thêm ở đây sẽ tính tiền xăng gấp đôi.
  ///
  /// Khi chuyến CHƯA hoàn tất và CHƯA ai ghi chi phí xăng xe thực tế, số này
  /// chỉ là ƯỚC TÍNH — ẩn hẳn khỏi tổng quan để tránh hiển thị quá sớm 1 con
  /// số trông như đã tiêu thật nhưng người dùng không biết nó tính cho gì
  /// (chỉ hiện lại đầy đủ trong "Chi phí ước tính" ở card Quản lý chi phí).
  Widget _buildTransportOverviewRow(ItineraryDetailEntity itin) {
    if (itin.transportCost <= 0) return const SizedBox.shrink();
    if (itin.status.toUpperCase() == 'COMPLETED') {
      return _buildTransportOverviewRowContent(itin);
    }
    return FutureBuilder<CostBreakdownEntity>(
      future: _ensureCostBreakdown(itin.id),
      builder: (context, snapshot) {
        if (snapshot.data?.transportIsActual != true) {
          return const SizedBox.shrink();
        }
        return _buildTransportOverviewRowContent(itin);
      },
    );
  }

  Widget _buildTransportOverviewRowContent(ItineraryDetailEntity itin) {
    final isMotorbike = itin.travelMode.toUpperCase() == 'MOTORBIKE';
    final formatter = NumberFormat('#,###', 'vi_VN');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isMotorbike
                  ? Icons.two_wheeler_rounded
                  : Icons.directions_car_filled_rounded,
              color: const Color(0xFF8B5CF6),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Xăng xe (cả chuyến)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1C1E),
              ),
            ),
          ),
          Text(
            '${formatter.format(itin.transportCost)}đ',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(ItineraryDetailEntity itin) {
    final visitCount = _totalVisitCount(itin);
    final isMotorbike = itin.travelMode.toUpperCase() == 'MOTORBIKE';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCardV2(
                value: '${itin.durationDays} ngày',
                icon: Icons.calendar_today_rounded,
                color: const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCardV2(
                value: '$visitCount địa điểm',
                icon: Icons.explore_rounded,
                color: const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Bọc IntrinsicHeight để card phương tiện cao bằng card người
        // lớn/trẻ em (card kia giờ 2 dòng nên cao hơn 1 dòng "Xe máy"/"Ô tô").
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _StatCardV2(
                  value: '${itin.adultCount} người lớn',
                  secondLine: itin.childCount > 0
                      ? '${itin.childCount} trẻ em'
                      : null,
                  icon: Icons.groups_rounded,
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCardV2(
                  value: isMotorbike ? 'Xe máy' : 'Ô tô',
                  icon: isMotorbike
                      ? Icons.two_wheeler_rounded
                      : Icons.directions_car_filled_rounded,
                  color: const Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Touchpoint duy nhất cho chi phí: gộp "Chi phí dự kiến" (số tổng, đã
  /// gồm 10% dự trù) + lối vào "Quản lý chi phí phát sinh" cũ thành 1 card,
  /// nguồn số liệu là `getCostBreakdown()` — CÙNG API mà [IncurredCostsScreen]
  /// dùng, để không còn 2 công thức tính ra 2 con số khác nhau.
  Widget _buildExpenseManagementCard(
    BuildContext context,
    ItineraryDetailEntity itin,
  ) {
    final formatter = NumberFormat('#,###', 'vi_VN');

    return FutureBuilder<CostBreakdownEntity>(
      future: _ensureCostBreakdown(itin.id),
      builder: (context, snapshot) {
        // Không phải thành viên lịch trình (VD đang xem lịch trình public
        // của người khác — backend chặn 403, xem incurred-costs.service.ts's
        // assertCallerIsMember) — ẩn hẳn card "Tổng quan chi phí" thay vì hiện
        // loading xoay vô tận. Trước đây chỉ check `!snapshot.hasData`,
        // không phân biệt "đang tải" với "tải lỗi vĩnh viễn" nên khi bị 403,
        // Future báo lỗi (không bao giờ có data) mà spinner cứ quay mãi.
        if (snapshot.hasError) return const SizedBox.shrink();
        final breakdown = snapshot.data;

        return InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => IncurredCostsScreen(
                  itineraryId: itin.id,
                  members: itin.members,
                  isCompleted: itin.status.toUpperCase() == 'COMPLETED',
                  days: itin.days,
                ),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.premiumBorder),
              boxShadow: [
                BoxShadow(
                  color: AppColors.premiumNavy.withValues(alpha: 0.045),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  CostUiLabels.overviewTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.costText,
                  ),
                ),
                const SizedBox(height: 16),
                if (breakdown == null)
                  const SizedBox(
                    height: 40,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  CostUiLabels.estimatedTotal,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.costTextMuted,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${formatter.format(breakdown.roundedGroupTotal)}đ',
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.costText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  breakdown.childCount > 0
                                      ? '${breakdown.adultCount} người lớn, ${breakdown.childCount} trẻ em'
                                      : '${breakdown.adultCount} người lớn',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.costTextMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.costHeroEnd.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.menu_book_rounded,
                              color: AppColors.costHeroEnd,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1, color: AppColors.premiumBorder),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              CostUiLabels.spendingLimit,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.costTextMuted,
                              ),
                            ),
                          ),
                          Text(
                            '${formatter.format(breakdown.payableLimitForGroup)}đ',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.costText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Lưu ý: Chi phí thực tế có thể thay đổi theo thời gian và địa điểm.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (breakdown != null) _buildSpendingProgress(breakdown),
                if (breakdown != null) ...[
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.premiumSoftBlue,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          child: Text(
                            CostUiLabels.viewDetails,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.premiumBlue,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: AppColors.premiumBlue,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Định dạng gọn số tiền theo triệu (vd 4.700.000đ -> "4,7tr") để hiện các
  /// mốc ước tính/dự trù/có thể chi trả gọn trong 1 dòng, không chiếm nhiều
  /// chỗ như hiển thị đầy đủ chữ số.
  String _compactMillion(double value) {
    final millions = value / 1000000;
    final rounded = (millions * 10).round() / 10;
    if (rounded == rounded.roundToDouble()) {
      return '${rounded.round()}tr';
    }
    return '${rounded.toStringAsFixed(1).replaceAll('.', ',')}tr';
  }

  /// Thanh tiến độ chi tiêu 3 vùng màu: xanh dương (ổn định, trong 90% chi phí
  /// ước tính) → cam (phần chi phí phát sinh, đã tính vào quỹ dự trù) → đỏ
  /// (chạm mức có thể chi trả người dùng tự nhập). Số trên cùng là tổng đã
  /// tiêu thực tế; các mốc bên dưới lấy từ [CostBreakdownEntity] — tính 1 lần
  /// duy nhất ở backend, không suy lại ở đây để tránh lệch số với "Sổ chi
  /// phí" chi tiết.
  Widget _buildSpendingProgress(CostBreakdownEntity breakdown) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    final estimated = breakdown.estimatedCostForGroup;
    final payable = breakdown.payableLimitForGroup;
    final spent = breakdown.spentSoFar;

    final blueEnd = estimated * 0.9;
    final orangeEnd = breakdown.roundedGroupTotal > blueEnd
        ? breakdown.roundedGroupTotal
        : blueEnd;
    final scale = [
      payable,
      orangeEnd,
      spent,
      1.0,
    ].reduce((a, b) => a > b ? a : b);

    final blueFrac = (blueEnd / scale).clamp(0.0, 1.0);
    final orangeFrac = ((orangeEnd - blueEnd) / scale).clamp(0.0, 1.0);
    final redFrac = (1.0 - blueFrac - orangeFrac).clamp(0.0, 1.0);

    final spentFrac = (spent / scale).clamp(0.0, 1.0);
    final Color spentColor;
    if (spent >= orangeEnd) {
      spentColor = const Color(0xFFDC2626);
    } else if (spent >= blueEnd) {
      spentColor = const Color(0xFFD97706);
    } else {
      spentColor = const Color(0xFF2563EB);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                CostUiLabels.spent,
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ),
            Text(
              '${formatter.format(spent)}đ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: spentColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 12,
            child: Stack(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: (blueFrac * 1000).round().clamp(1, 100000),
                      child: Container(color: const Color(0xFFDBEAFE)),
                    ),
                    Expanded(
                      flex: (orangeFrac * 1000).round().clamp(1, 100000),
                      child: Container(color: const Color(0xFFFEF3C7)),
                    ),
                    Expanded(
                      flex: (redFrac * 1000).round().clamp(1, 100000),
                      child: Container(color: const Color(0xFFFEE2E2)),
                    ),
                  ],
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOut,
                      width: constraints.maxWidth * spentFrac,
                      height: 12,
                      color: spentColor,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            Text(
              '${CostUiLabels.beforeReserve}: ${_compactMillion(estimated)}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
            Text(
              'Dự trù: ${_compactMillion(breakdown.reserveCost)}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
            Text(
              '${CostUiLabels.spendingLimit}: ${_compactMillion(payable)}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ],
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
                        .map<Widget>(
                          (day) => _buildShortItineraryItem(
                            sheetContext,
                            itin,
                            day,
                            isFromSheet: true,
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
    String btnText = 'XEM CHI TIẾT LỊCH TRÌNH';
    IconData btnIcon = Icons.arrow_forward;
    void onPressed() => _navigateToDetail(context, itin);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SectionHeader(title: 'Ghi chú cho chuyến đi'),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
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
        ),
      ],
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
    final category = (activity.category ?? '').trim().toLowerCase();
    if (category.isNotEmpty) {
      // The backend already classifies this precisely (category == 'hotel'
      // for the real accommodation row). Trust it instead of guessing from
      // the free-text title, which can contain words like "homestay" in a
      // café's own name (e.g. "The Laban - Cafe & Homestay") and cause a
      // false positive that inflates the hotel count/name shown here.
      return category == 'hotel' ||
          category.contains('lưu trú') ||
          category.contains('khách sạn') ||
          category.contains('accommodation');
    }
    final title = activity.title.toLowerCase();
    return title.contains('hotel') ||
        title.contains('khách sạn') ||
        title.contains('resort') ||
        title.contains('homestay') ||
        title.contains('villa');
  }

  List<ItineraryActivityEntity> _visitActivities(ItineraryDayEntity day) {
    return day.activities
        .where((activity) => !_isHotelStart(activity))
        .toList();
  }

  // Trả về hoạt động khách sạn thật (không chỉ tên) — cần placeId cho nút
  // "Xem chi tiết địa điểm" ở card tổng quan khách sạn.
  ItineraryActivityEntity? _hotelActivity(ItineraryDetailEntity itin) {
    for (final day in itin.days) {
      for (final activity in day.activities.where(_isHotelStart)) {
        return activity;
      }
    }
    return null;
  }

  void _openHotelPlaceDetail(ItineraryActivityEntity hotelActivity) {
    final placeId = hotelActivity.placeId ?? hotelActivity.id;
    if (placeId.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => sl<PlaceDetailCubit>(),
          child: PlaceDetailScreen(placeId: placeId, showRelatedPlaces: true),
        ),
      ),
    );
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
}

class _CostSnapshot {
  final int totalVisitCount;
  final int visitedCount;

  const _CostSnapshot({
    required this.totalVisitCount,
    required this.visitedCount,
  });
}

class _StatCardV2 extends StatelessWidget {
  final String value;
  final String? secondLine;
  final IconData icon;
  final Color color;

  const _StatCardV2({
    required this.value,
    this.secondLine,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
        mainAxisAlignment: MainAxisAlignment.center,
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
          if (secondLine != null) ...[
            const SizedBox(height: 4),
            Text(
              secondLine!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Card "Chỗ ở" ở Tổng quan chuyến đi — khác _StatCardV2 (chỉ label/value 1
/// dòng) vì cần thêm đơn giá/đêm/người và tổng tiền cả chuyến.
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

class _ItineraryShareSheet extends StatefulWidget {
  final ItineraryDetailEntity itinerary;
  final ItineraryCubit cubit;
  final ScaffoldMessengerState messenger;

  const _ItineraryShareSheet({
    required this.itinerary,
    required this.cubit,
    required this.messenger,
  });

  @override
  State<_ItineraryShareSheet> createState() => _ItineraryShareSheetState();
}

class _ItineraryShareSheetState extends State<_ItineraryShareSheet> {
  final TextEditingController _controller = TextEditingController();
  int _recipientSearchGeneration = 0;
  bool _isSubmitting = false;
  bool _isCreatingLink = false;
  bool _isSearchingRecipients = false;
  bool _hasSearched = false;
  String? _errorText;
  ItineraryShareLink? _shareLink;
  List<ItineraryShareRecipient> _recipientResults = const [];
  ItineraryShareRecipient? _selectedRecipient;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<ItineraryShareLink?> _ensureShareLink() async {
    if (_shareLink != null) return _shareLink;
    setState(() => _isCreatingLink = true);
    try {
      final created = await widget.cubit.createShareLink(widget.itinerary.id);
      if (!mounted) return null;
      setState(() {
        _shareLink = created;
        _isCreatingLink = false;
      });
      return created;
    } catch (e) {
      if (!mounted) return null;
      setState(() => _isCreatingLink = false);
      widget.messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Không thể tạo link chia sẻ: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return null;
    }
  }

  Future<void> _copyShareLink() async {
    final link = await _ensureShareLink();
    if (link == null) return;
    await Clipboard.setData(ClipboardData(text: link.message));
    widget.messenger
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          content: Text('Đã sao chép link mời tham gia lịch trình'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _nativeShare() async {
    final link = await _ensureShareLink();
    if (link == null) return;
    await Share.share(link.message);
  }

  /// Người dùng nhập xong rồi bấm nút tìm kiếm mới gọi API,
  /// không tự tìm khi đang gõ.
  Future<void> _performRecipientSearch() async {
    FocusScope.of(context).unfocus();
    final query = _controller.text.trim();
    _recipientSearchGeneration++;

    if (query.length < 2) {
      setState(() {
        _hasSearched = false;
        _selectedRecipient = null;
        _recipientResults = const [];
        _isSearchingRecipients = false;
        _errorText = 'Vui lòng nhập ít nhất 2 ký tự để tìm kiếm';
      });
      return;
    }

    setState(() {
      _selectedRecipient = null;
      _errorText = null;
      _isSearchingRecipients = true;
    });

    final generation = _recipientSearchGeneration;
    try {
      final users = await widget.cubit.searchShareRecipients(query);
      if (!mounted || generation != _recipientSearchGeneration) return;
      setState(() {
        _recipientResults = users;
        _hasSearched = true;
        _isSearchingRecipients = false;
      });
    } catch (e) {
      if (!mounted || generation != _recipientSearchGeneration) return;
      setState(() {
        _recipientResults = const [];
        _hasSearched = false;
        _isSearchingRecipients = false;
        _errorText = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  /// Khi sửa nội dung ô nhập thì bỏ kết quả/lựa chọn cũ,
  /// chờ người dùng bấm tìm kiếm lại.
  void _onQueryChanged(String value) {
    if (_selectedRecipient == null &&
        !_hasSearched &&
        _recipientResults.isEmpty &&
        _errorText == null) {
      return;
    }
    _recipientSearchGeneration++;
    setState(() {
      _selectedRecipient = null;
      _recipientResults = const [];
      _hasSearched = false;
      _isSearchingRecipients = false;
      _errorText = null;
    });
  }

  Future<void> _submit() async {
    final recipient = _selectedRecipient;
    if (recipient == null) {
      setState(() => _errorText = 'Vui lòng chọn người nhận trong danh sách');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      await widget.cubit.shareItinerary(widget.itinerary.id, recipient.email);
      if (!mounted) return;
      Navigator.pop(context);
      widget.messenger.clearSnackBars();
      widget.messenger.showSnackBar(
        const SnackBar(
          content: Text('Đã gửi lời mời chia sẻ lịch trình'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _isSubmitting = false;
        _errorText = message.isEmpty
            ? 'Không thể gửi lời mời, vui lòng thử lại'
            : message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboardBottom = media.viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: keyboardBottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight:
              media.size.height - media.padding.top - keyboardBottom - 12,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + media.padding.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Row(
                  children: [
                    Icon(Icons.ios_share_rounded, color: Color(0xFF2563EB)),
                    SizedBox(width: 10),
                    Text(
                      'Chia sẻ lịch trình',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  widget.itinerary.title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 18),
                const Text(
                  'Mời trực tiếp',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.search,
                        enabled: !_isSubmitting,
                        onSubmitted: (_) => _performRecipientSearch(),
                        onChanged: _onQueryChanged,
                        decoration: InputDecoration(
                          hintText: 'Nhập email, số điện thoại hoặc họ tên',
                          prefixIcon: const Icon(
                            Icons.person_add_alt_1_rounded,
                          ),
                          errorText: _errorText,
                          // Cảnh báo "đã đủ số người lớn..." từ backend khá
                          // dài (~190 ký tự) — 2 dòng cũ bị cắt mất phần
                          // hướng dẫn cuối câu. Tăng lên đủ dòng để hiển thị
                          // trọn vẹn, không ảnh hưởng các thông báo ngắn khác
                          // (chỉ chiếm đúng số dòng thực tế cần).
                          errorMaxLines: 6,
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFF2563EB),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSubmitting || _isSearchingRecipients
                            ? null
                            : _performRecipientSearch,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFF93C5FD),
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isSearchingRecipients
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.search_rounded, size: 24),
                      ),
                    ),
                  ],
                ),
                if (_hasSearched) ...[
                  const SizedBox(height: 10),
                  if (_recipientResults.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        'Mình chưa thấy tài khoản phù hợp. Bạn thử nhập email, số điện thoại hoặc họ tên khác nhé.',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    ..._recipientResults.map(
                      (user) => _ShareRecipientTile(
                        user: user,
                        selected: _selectedRecipient?.id == user.id,
                        onTap: () {
                          setState(() {
                            _selectedRecipient = user;
                            _errorText = null;
                          });
                        },
                      ),
                    ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting || _selectedRecipient == null
                        ? null
                        : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(_isSubmitting ? 'Đang gửi...' : 'Chia sẻ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF93C5FD),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const Divider(height: 1),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Chia sẻ link qua mạng xã hội',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (_isCreatingLink)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _ShareChannelButton(
                      icon: Icons.link_rounded,
                      label: 'Sao chép',
                      color: const Color(0xFF475569),
                      onTap: _isCreatingLink ? null : _copyShareLink,
                    ),
                    _ShareChannelButton(
                      icon: Icons.ios_share_rounded,
                      label: 'Chia sẻ',
                      color: const Color(0xFF0F766E),
                      onTap: _isCreatingLink ? null : _nativeShare,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShareRecipientTile extends StatelessWidget {
  final ItineraryShareRecipient user;
  final bool selected;
  final VoidCallback onTap;

  const _ShareRecipientTile({
    required this.user,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Kết quả tìm kiếm chỉ hiển thị họ tên, không lộ email/số điện thoại.
    final displayName = user.fullName.trim().isNotEmpty
        ? user.fullName.trim()
        : 'Người dùng ẩn danh';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFFE2E8F0),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: selected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFE0F2FE),
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF0369A1),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShareChannelButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ShareChannelButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ShareChannelButton> createState() => _ShareChannelButtonState();
}

class _ShareChannelButtonState extends State<_ShareChannelButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    final enabled = widget.onTap != null;
    final hovered = _hovered && enabled;

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(
              alpha: !enabled
                  ? 0.06
                  : hovered
                  ? 0.20
                  : 0.10,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withValues(alpha: hovered ? 0.45 : 0.18),
            ),
            boxShadow: hovered
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.22),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : const [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 18, color: color.withValues(alpha: 0.9)),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
