import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/itinerary_entity.dart';
import '../cubit/itinerary_cubit.dart';
import '../cubit/itinerary_state.dart';
import '../widgets/itinerary_card.dart';
import '../widgets/itinerary_completed_card.dart';
import '../widgets/itinerary_empty_view.dart';
import '../widgets/itinerary_filter_chips.dart';
import '../widgets/itinerary_summary_grid.dart';

/// Màn hình chính "Lịch trình của tôi".
///
/// Sử dụng [BlocProvider] để cung cấp [ItineraryCubit],
/// và [BlocBuilder] để render UI tương ứng với 4 trạng thái.
class ItineraryScreen extends StatelessWidget {
  const ItineraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ItineraryCubit>()..loadData(),
      child: const _ItineraryView(),
    );
  }
}

class _ItineraryView extends StatelessWidget {
  const _ItineraryView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocBuilder<ItineraryCubit, ItineraryState>(
          builder: (context, state) {
            // ── Initial ───────────────────────────────────────────────────
            if (state is ItineraryInitial) {
              return const SizedBox.shrink();
            }

            // ── Loading (Shimmer placeholder) ─────────────────────────────
            if (state is ItineraryLoading) {
              return _buildLoadingShimmer();
            }

            // ── Error + Retry ─────────────────────────────────────────────
            if (state is ItineraryError) {
              return _buildErrorView(context, state.message);
            }

            // ── Loaded ────────────────────────────────────────────────────
            final loaded = state as ItineraryLoaded;
            return _buildLoadedView(context, loaded);
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── LOADED VIEW ────────────────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLoadedView(BuildContext context, ItineraryLoaded state) {
    final cubit = context.read<ItineraryCubit>();

    return CustomScrollView(
      slivers: [
        // ── App Bar ──────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Lịch trình của tôi',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                ),
                // Icon tìm kiếm
                _iconButton(Icons.search, () {}),
                const SizedBox(width: 8),
                // Icon bộ lọc
                _iconButton(Icons.tune, () {}),
              ],
            ),
          ),
        ),

        // ── Filter Chips ─────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: ItineraryFilterChips(
              activeFilter: state.activeFilter,
              onChanged: (status) => cubit.filterBy(status),
            ),
          ),
        ),

        // ── Summary Grid ─────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: ItinerarySummaryGrid(summary: state.summary),
          ),
        ),

        // ── Danh sách lịch trình hoặc Empty ──────────────────────────────
        if (state.itineraries.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: ItineraryEmptyView(
              onCreateTap: () {
                // TODO: navigate to create itinerary screen
              },
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                // Thêm khoảng cách đầu danh sách.
                if (index == 0) return const SizedBox(height: 12);
                // Thêm khoảng cách cuối danh sách (tránh bị bottom nav che).
                if (index == state.itineraries.length + 1) {
                  return const SizedBox(height: 100);
                }

                final item = state.itineraries[index - 1];
                if (item.status == ItineraryStatus.completed) {
                  return ItineraryCompletedCard(
                    item: item,
                    onTap: () {},
                    onEdit: () {},
                    onDelete: () => cubit.deleteItem(item.id),
                  );
                }
                return ItineraryCard(
                  item: item,
                  onTap: () {},
                  onEdit: () {},
                  onDelete: () => cubit.deleteItem(item.id),
                );
              },
              // +2 cho spacer đầu và cuối.
              childCount: state.itineraries.length + 2,
            ),
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── LOADING SHIMMER ────────────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLoadingShimmer() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title shimmer
          _shimmerBox(width: 200, height: 24),
          const SizedBox(height: 20),
          // Filter chips shimmer
          Row(
            children: List.generate(
                4,
                (i) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _shimmerBox(width: 70, height: 32, radius: 16),
                    )),
          ),
          const SizedBox(height: 20),
          // Stats grid shimmer
          Row(
            children: [
              Expanded(child: _shimmerBox(height: 70, radius: 12)),
              const SizedBox(width: 12),
              Expanded(child: _shimmerBox(height: 70, radius: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _shimmerBox(height: 70, radius: 12)),
              const SizedBox(width: 12),
              Expanded(child: _shimmerBox(height: 70, radius: 12)),
            ],
          ),
          const SizedBox(height: 20),
          // Card shimmer
          _shimmerBox(height: 200, radius: 16),
          const SizedBox(height: 12),
          _shimmerBox(height: 120, radius: 16),
        ],
      ),
    );
  }

  Widget _shimmerBox({double? width, double height = 20, double radius = 8}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── ERROR VIEW ─────────────────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildErrorView(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text(
              'Đã xảy ra lỗi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 160,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () =>
                    context.read<ItineraryCubit>().loadData(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Thử lại',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ── HELPERS ────────────────────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF374151)),
      ),
    );
  }
}
