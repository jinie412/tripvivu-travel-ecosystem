import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/cubit/itinerary_cubit.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/cubit/itinerary_state.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/widgets/itinerary_card.dart';

import 'itinerary_summary_screen.dart';

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
                // TODO: navigate to create itinerary screen
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
                    final hasOngoing = state.itineraries.any(
                      (i) => i.status == ItineraryStatus.ongoing,
                    );
                    if (hasOngoing && item.status != ItineraryStatus.ongoing) {
                      showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
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
                                    child: Icon(
                                      Icons.warning_amber_rounded,
                                      color: Color(0xFFEF4444),
                                      size: 32,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Đang có chuyến đi khác!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1C1C1E),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
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
                                    child: Text(
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
            }, childCount: state.itineraries.length + 2),
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
