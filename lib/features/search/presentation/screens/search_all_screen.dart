import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:travel_advisor_mobile/core/di/injection_container.dart';
import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/features/city_detail/domain/entities/city_entities.dart';
import 'package:travel_advisor_mobile/features/city_detail/presentation/widgets/itinerary_vertical_card.dart';
import 'package:travel_advisor_mobile/features/city_detail/presentation/widgets/activity_vertical_card.dart';
import 'package:travel_advisor_mobile/features/city_detail/presentation/widgets/restaurant_vertical_card.dart';
import 'package:travel_advisor_mobile/features/city_detail/presentation/widgets/hotel_vertical_card.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/cubit/itinerary_cubit.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/screens/itinerary_summary_screen.dart';
import 'package:travel_advisor_mobile/features/itinerary/tracking/presentation/cubit/tracking_cubit.dart';
import 'package:travel_advisor_mobile/features/place/presentation/cubit/place_detail_cubit.dart';
import 'package:travel_advisor_mobile/features/place/presentation/screens/place_detail_screen.dart';
import 'package:travel_advisor_mobile/features/search/domain/entities/search_results.dart';
import 'package:travel_advisor_mobile/features/search/presentation/cubit/search_all_cubit.dart';
import 'package:travel_advisor_mobile/features/search/presentation/cubit/search_all_state.dart';

class SearchAllScreen extends StatelessWidget {
  final String query;

  const SearchAllScreen({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SearchAllCubit>()..loadAll(query),
      child: _SearchAllView(query: query),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SearchAllView extends StatefulWidget {
  final String query;
  const _SearchAllView({required this.query});

  @override
  State<_SearchAllView> createState() => _SearchAllViewState();
}

class _SearchAllViewState extends State<_SearchAllView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      context.read<SearchAllCubit>().loadMore();
    }
  }

  void _openFilterSheet(
    BuildContext context, {
    required SearchType? typeFilter,
    required String? cityFilter,
    required List<String> cities,
  }) {
    final cubit = context.read<SearchAllCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FilterSheet(
        typeFilter: typeFilter,
        cityFilter: cityFilter,
        cities: cities,
        onApply: (type, city) {
          cubit.applyTypeFilter(type);
          cubit.applyCityFilter(city);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 80,
        leading: BackButton(
          color: AppColors.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Text(
            'Kết quả tìm kiếm của "${widget.query}"',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.35,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        actions: [
          BlocBuilder<SearchAllCubit, SearchAllState>(
            builder: (context, state) {
              final loaded = state.mapOrNull(loaded: (s) => s);
              final hasFilter = loaded != null &&
                  (loaded.typeFilter != null || loaded.cityFilter != null);
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.tune_rounded,
                        color: AppColors.textPrimary),
                    onPressed: loaded == null
                        ? null
                        : () => _openFilterSheet(
                              context,
                              typeFilter: loaded.typeFilter,
                              cityFilter: loaded.cityFilter,
                              cities: loaded.cities,
                            ),
                  ),
                  if (hasFilter)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: BlocBuilder<SearchAllCubit, SearchAllState>(
        builder: (context, state) => state.when(
          initial: () => const SizedBox.shrink(),
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          loaded: (allItems, cities, q, typeFilter, cityFilter, displayedCount) {
            final cubit = context.read<SearchAllCubit>();
            final allFiltered = cubit.filteredItems(state);
            final displayedItems = allFiltered.take(displayedCount).toList();
            final hasMore = displayedCount < allFiltered.length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Text(
                    '${allFiltered.length} kết quả',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () =>
                        context.read<SearchAllCubit>().loadAll(widget.query),
                    color: AppColors.primary,
                    child: displayedItems.isEmpty
                        ? LayoutBuilder(
                            builder: (_, c) => SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: SizedBox(
                                height: c.maxHeight,
                                child: _EmptyView(query: q),
                              ),
                            ),
                          )
                        : _FlatList(
                            items: displayedItems,
                            hasMore: hasMore,
                            scrollController: _scrollController,
                          ),
                  ),
                ),
              ],
            );
          },
          error: (msg) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline,
                    size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(msg,
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 15)),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () =>
                      context.read<SearchAllCubit>().loadAll(widget.query),
                  child: const Text('Thử lại',
                      style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter bottom sheet

class _FilterSheet extends StatefulWidget {
  final SearchType? typeFilter;
  final String? cityFilter;
  final List<String> cities;
  final void Function(SearchType? type, String? city) onApply;

  const _FilterSheet({
    required this.typeFilter,
    required this.cityFilter,
    required this.cities,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  SearchType? _selectedType;
  String? _selectedCity;

  static const _typeOptions = [
    (null, 'Tất cả'),
    (SearchType.itinerary, 'Lịch trình'),
    (SearchType.activity, 'Hoạt động tham quan'),
    (SearchType.restaurant, 'Nhà hàng/Quán ăn'),
    (SearchType.hotel, 'Khách sạn / Lưu trú'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.typeFilter;
    _selectedCity = widget.cityFilter;
  }

  bool get _hasFilter => _selectedType != null || _selectedCity != null;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text(
                  'Lọc kết quả',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (_hasFilter)
                  GestureDetector(
                    onTap: () => setState(() {
                      _selectedType = null;
                      _selectedCity = null;
                    }),
                    child: const Text(
                      'Đặt lại',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Loại hình',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                _DropdownField<SearchType?>(
                  value: _selectedType,
                  hint: 'Tất cả',
                  items: _typeOptions
                      .map((o) => DropdownMenuItem<SearchType?>(
                            value: o.$1,
                            child: Text(o.$2),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedType = v),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Tỉnh / Thành phố',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                _DropdownField<String?>(
                  value: _selectedCity,
                  hint: 'Tất cả tỉnh/TP',
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Tất cả tỉnh/TP'),
                    ),
                    ...widget.cities.map((c) => DropdownMenuItem<String?>(
                          value: c,
                          child: Text(c),
                        )),
                  ],
                  onChanged: (v) => setState(() => _selectedCity = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  widget.onApply(_selectedType, _selectedCity);
                  Navigator.pop(context);
                },
                child: const Text(
                  'Áp dụng',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final T value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _DropdownField({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.inputBorder),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint,
              style: const TextStyle(color: AppColors.textSecondary)),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary),
          items: items,
          onChanged: onChanged,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _FlatList extends StatelessWidget {
  final List<FlatSearchItem> items;
  final bool hasMore;
  final ScrollController scrollController;

  const _FlatList({
    required this.items,
    required this.hasMore,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: items.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2),
            ),
          );
        }
        final item = items[index];
        return GestureDetector(
          onTap: () => _navigateToDetail(context, item),
          child: _buildCard(item),
        );
      },
    );
  }

  Widget _buildCard(FlatSearchItem item) {
    switch (item.type) {
      case SearchType.itinerary:
        return ItineraryVerticalCard(item: item.data as CityItinerary);
      case SearchType.activity:
        return ActivityVerticalCard(item: item.data as CityActivity);
      case SearchType.restaurant:
        return RestaurantVerticalCard(item: item.data as CityRestaurant);
      case SearchType.hotel:
        return HotelVerticalCard(item: item.data as CityHotel);
    }
  }

  void _navigateToDetail(BuildContext context, FlatSearchItem item) {
    if (item.type == SearchType.itinerary) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => sl<ItineraryCubit>()),
              BlocProvider(create: (_) => sl<TrackingCubit>()),
            ],
            child: ItinerarySummaryScreen(itineraryId: item.id),
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => sl<PlaceDetailCubit>(),
            child: PlaceDetailScreen(placeId: item.id),
          ),
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final String query;
  const _EmptyView({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy kết quả cho "$query"',
            style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
