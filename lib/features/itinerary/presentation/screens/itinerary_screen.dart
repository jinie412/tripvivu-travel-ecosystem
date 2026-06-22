import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/cubit/itinerary_cubit.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/cubit/itinerary_state.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/widgets/itinerary_card.dart';
import 'package:travel_advisor_mobile/features/itinerary/tracking/presentation/cubit/tracking_cubit.dart';
import 'package:travel_advisor_mobile/features/itinerary/tracking/presentation/cubit/tracking_state.dart';
import 'package:travel_advisor_mobile/features/itinerary/tracking/presentation/widgets/tracking_permissions.dart';

import 'itinerary_summary_screen.dart';
import 'package:travel_advisor_mobile/features/trip_planner/presentation/screens/trip_planner_screen.dart';

import 'package:travel_advisor_mobile/core/widgets/error_view.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/widgets/itinerary_empty_view.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/widgets/itinerary_filter_chips.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/widgets/itinerary_summary_grid.dart';

/// Màn hình chính "Lịch trình của tôi".
class ItineraryScreen extends StatelessWidget {
  const ItineraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ItineraryView();
  }
}

class _ItineraryView extends StatefulWidget {
  const _ItineraryView();

  @override
  State<_ItineraryView> createState() => _ItineraryViewState();
}

class _ItineraryViewState extends State<_ItineraryView> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchOpen = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ItineraryCubit, ItineraryState>(
      builder: (context, state) {
        if (state is ItineraryInitial) {
          return const SizedBox.shrink();
        }

        if (state is ItineraryLoading) {
          return _buildLoadingShimmer();
        }

        if (state is ItineraryError) {
          return ErrorView(
            error: state.message,
            onRetry: () => context.read<ItineraryCubit>().loadData(),
          );
        }

        final loaded = state as ItineraryLoaded;
        return _buildLoadedView(context, loaded);
      },
    );
  }

  Widget _buildLoadedView(BuildContext context, ItineraryLoaded state) {
    final cubit = context.read<ItineraryCubit>();
    final hasSearch = state.searchQuery.isNotEmpty || _isSearchOpen;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 24,
              right: 24,
            ),
            child: Row(
              children: [
                _iconButton(Icons.menu, () {
                  Scaffold.of(context).openDrawer();
                }),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Lịch trình của tôi',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                if (state.itineraries.isNotEmpty) ...[
                  _iconButton(Icons.search, () {
                    setState(() => _isSearchOpen = true);
                    _searchFocusNode.requestFocus();
                  }),
                ],
              ],
            ),
          ),
        ),

        if (hasSearch)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: _buildSearchField(context, state),
            ),
          ),

        if (state.summary.total > 0) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ItineraryFilterChips(
                activeFilter: state.activeFilter,
                activeSubFilter: state.activeCompletedFilter,
                onChanged: (status) => cubit.filterBy(status),
                onSubFilterChanged: (filter) => cubit.filterByCompleted(filter),
              ),
            ),
          ),
          if (state.itineraries.isNotEmpty &&
              state.activeFilter == null &&
              !hasSearch)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ItinerarySummaryGrid(summary: state.summary),
              ),
            ),
        ],

        if (state.itineraries.isEmpty && hasSearch)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _SearchEmptyView(query: state.searchQuery),
          )
        else if (state.itineraries.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: ItineraryEmptyView(
              onCreateTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const TripPlannerScreen(),
                  ),
                );
              },
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              if (index == 0) return const SizedBox(height: 16);
              if (index == state.itineraries.length + 1) {
                return const SizedBox(height: 100);
              }

              final item = state.itineraries[index - 1];
              void onCardTap() async {
                cubit.selectItinerary(item.id);
                  final trackingCubit = context.read<TrackingCubit>();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MultiBlocProvider(
                        providers: [
                          BlocProvider.value(value: cubit),
                        BlocProvider.value(value: trackingCubit),
                        ],
                      child: ItinerarySummaryScreen(itineraryId: item.id),
                    ),
                  ),
                );
              }

                return _ItineraryCardWithStart(
                  item: item,
                  onCardTap: onCardTap,
                  onDelete: () => cubit.deleteItem(item.id),
                );
              },
              childCount: state.itineraries.length + 2,
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingShimmer() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildSearchField(BuildContext context, ItineraryLoaded state) {
    final cubit = context.read<ItineraryCubit>();

    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        textInputAction: TextInputAction.search,
        onChanged: cubit.searchByTitle,
        decoration: InputDecoration(
          hintText: 'Tìm lịch trình...',
          prefixIcon: const Icon(
            Icons.search,
            size: 20,
            color: Color(0xFF64748B),
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.isSearching)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  color: const Color(0xFF64748B),
                  onPressed: () {
                    _searchController.clear();
                    cubit.clearSearch();
                  },
                ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_up, size: 22),
                color: const Color(0xFF64748B),
                onPressed: () {
                  _searchController.clear();
                  cubit.clearSearch();
                  setState(() => _isSearchOpen = false);
                  _searchFocusNode.unfocus();
                },
              ),
            ],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF1A6EBD)),
      ),
    );
  }

}

/// Card lịch trình + nút "BẮT ĐẦU / ĐANG DIỄN RA" nhúng vào cuối card.
class _ItineraryCardWithStart extends StatelessWidget {
  final ItineraryEntity item;
  final VoidCallback onCardTap;
  final VoidCallback onDelete;

  const _ItineraryCardWithStart({
    required this.item,
    required this.onCardTap,
    required this.onDelete,
  });

  bool get _shouldShowStart => item.status != ItineraryStatus.completed;

  @override
  Widget build(BuildContext context) {
    return ItineraryCard(
      item: item,
      onTap: onCardTap,
      onEdit: () {},
      onDelete: onDelete,
      bottomChild: _shouldShowStart ? _StartButton(item: item) : null,
    );
  }
}

class _StartButton extends StatefulWidget {
  final ItineraryEntity item;
  const _StartButton({required this.item});

  @override
  State<_StartButton> createState() => _StartButtonState();
}

class _StartButtonState extends State<_StartButton> {
  bool _loading = false;

  bool _isTodayStartDate() {
    final startDate = widget.item.startDate;
    if (startDate == null) return true;
    final now = DateTime.now();
    return startDate.year == now.year &&
        startDate.month == now.month &&
        startDate.day == now.day;
  }

  String _formatStartDate() {
    final d = widget.item.startDate;
    if (d == null) return '';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  bool _isOngoing(TrackingState trackingState) {
    if (widget.item.trackingActive) return true;
    return trackingState.isActive && trackingState.itineraryId == widget.item.id;
  }

  Future<void> _onTap(bool isOngoing) async {
    if (isOngoing) {
      await _confirmStop();
      return;
    }

    if (!_isTodayStartDate()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Lịch trình chỉ có thể bắt đầu vào ngày ${_formatStartDate()}.'),
          duration: const Duration(seconds: 3),
        ));
      }
      return;
    }

    final cubit = context.read<TrackingCubit>();
    final itinState = context.read<ItineraryCubit>().state;
    final hasConflict = (cubit.state.isActive && cubit.state.itineraryId != widget.item.id) ||
        (itinState is ItineraryLoaded &&
            itinState.itineraries.any(
              (i) => i.id != widget.item.id && i.trackingActive,
            ));
    if (hasConflict) {
      _showConflictDialog();
      return;
    }

    setState(() => _loading = true);
    try {
      final perm = await TrackingPermissions.ensure();
      if (!mounted) return;

      if (perm != TrackingPermResult.granted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(TrackingPermissions.messageFor(perm)),
          action: perm == TrackingPermResult.deniedBackground
              ? SnackBarAction(label: 'Mở Cài đặt', onPressed: openAppSettings)
              : null,
        ));
        return;
      }

      final date = widget.item.startDate ?? DateTime.now();
      await context.read<TrackingCubit>().start(
        itineraryId: widget.item.id,
        date: date,
      );
      if (!mounted) return;
      context.read<ItineraryCubit>().toggleItineraryStatus(widget.item.id, true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmStop() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dừng theo dõi?'),
        content: const Text('Geofence sẽ được gỡ và không tự đánh dấu địa điểm nữa.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Dừng')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await context.read<TrackingCubit>().stop();
    if (!mounted) return;
    context.read<ItineraryCubit>().toggleItineraryStatus(widget.item.id, false);
  }

  void _showConflictDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(color: Color(0xFFFEF2F2), shape: BoxShape.circle),
                child: const Center(child: Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 32)),
              ),
              const SizedBox(height: 16),
              const Text('Đang có chuyến đi khác!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1C1C1E))),
              const SizedBox(height: 8),
              const Text(
                'Bạn đang có một lịch trình đang diễn ra.\nVui lòng hoàn thành chuyến đi hiện tại để bắt đầu lịch trình mới.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.4),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Đã hiểu',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TrackingCubit, TrackingState>(
      buildWhen: (p, c) => p.isActive != c.isActive || p.itineraryId != c.itineraryId,
      builder: (context, trackingState) {
        final isOngoing = _isOngoing(trackingState);
        final isLocked = !isOngoing && !_isTodayStartDate();
        final color = isOngoing
            ? const Color(0xFF2563EB)
            : isLocked
                ? const Color(0xFF9CA3AF)
                : const Color(0xFF0E9E87);
        final bgColor = isOngoing
            ? const Color(0xFFEFF6FF)
            : isLocked
                ? const Color(0xFFF3F4F6)
                : const Color(0xFFE8FDF8);

        return GestureDetector(
          onTap: _loading ? null : () => _onTap(isOngoing),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: bgColor,
            child: Row(
              children: [
                if (_loading)
                  SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: color),
                  )
                else
                  Icon(
                    isOngoing
                        ? Icons.location_searching
                        : isLocked
                            ? Icons.calendar_today_outlined
                            : Icons.play_circle_outline_rounded,
                    size: 16,
                    color: color,
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isOngoing
                        ? 'ĐANG DIỄN RA'
                        : isLocked
                            ? 'BẮT ĐẦU NGÀY ${_formatStartDate()}'
                            : 'BẮT ĐẦU LỊCH TRÌNH',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.5),
                  ),
                ),
                Icon(
                  isOngoing
                      ? Icons.stop_circle_outlined
                      : isLocked
                          ? Icons.lock_outline_rounded
                          : Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: color,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}



class _SearchEmptyView extends StatelessWidget {
  final String query;

  const _SearchEmptyView({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off,
                color: Color(0xFF1A6EBD),
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Không tìm thấy lịch trình',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              query.isEmpty
                  ? 'Thử nhập tên lịch trình khác.'
                  : 'Không có kết quả phù hợp với "$query".',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
