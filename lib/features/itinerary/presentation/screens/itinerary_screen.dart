import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/itinerary_entity.dart';
import '../cubit/itinerary_cubit.dart';
import '../cubit/itinerary_state.dart';
import '../widgets/itinerary_card.dart';

import '../widgets/itinerary_empty_view.dart';
import '../widgets/itinerary_filter_chips.dart';
import '../widgets/itinerary_summary_grid.dart';
import '../../../../core/widgets/error_view.dart';
import 'itinerary_summary_screen.dart';

/// Màn hình chính "Lịch trình của tôi".
class ItineraryScreen extends StatelessWidget {
  const ItineraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ItineraryView();
  }
}

class _ItineraryView extends StatelessWidget {
  const _ItineraryView();

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

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24,
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
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                if (state.itineraries.isNotEmpty) ...[
                  _iconButton(Icons.search, () {}),
                ],
              ],
            ),
          ),
        ),

        if (state.itineraries.isNotEmpty) ...[
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
          if (state.itineraries.isNotEmpty && state.activeFilter == null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ItinerarySummaryGrid(summary: state.summary),
              ),
            ),
        ],

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
                if (index == 0) return const SizedBox(height: 12);
                if (index == state.itineraries.length + 1) {
                  return const SizedBox(height: 100);
                }

                final item = state.itineraries[index - 1];
                void onCardTap() async {
                  cubit.selectItinerary(item.id);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: cubit,
                        child: ItinerarySummaryScreen(itineraryId: item.id),
                      ),
                    ),
                  );
                }

                return ItineraryCard(
                  item: item,
                  onTap: onCardTap,
                  onEdit: () {},
                  onDelete: () => cubit.deleteItem(item.id),
                  onStartToggle: (val) {
                    if (val) {
                      final hasOngoing = state.itineraries.any((i) => i.status == ItineraryStatus.ongoing);
                      if (hasOngoing && item.status != ItineraryStatus.ongoing) {
                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFEF2F2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 32),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Đang có chuyến đi khác!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1C1C1E),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Bạn đang có một lịch trình đang diễn ra.\nVui lòng hoàn thành chuyến đi hiện tại để có thể bắt đầu lịch trình mới.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF6B7280),
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF2563EB),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: const Text(
                                        'Đã hiểu',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                        return;
                      }
                    }
                    cubit.toggleItineraryStatus(item.id, val);
                  },
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
