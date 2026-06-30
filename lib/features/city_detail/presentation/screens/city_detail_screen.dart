import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:travel_advisor_mobile/core/di/injection_container.dart';
import 'package:travel_advisor_mobile/core/navigation/main_shell.dart';
import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/core/widgets/page_dots.dart';
import 'package:travel_advisor_mobile/core/widgets/section_header.dart';
import 'package:travel_advisor_mobile/features/city_detail/domain/entities/city_entities.dart';
import 'package:travel_advisor_mobile/features/city_detail/domain/entities/filter_enums.dart';
import 'package:travel_advisor_mobile/features/city_detail/presentation/cubit/city_detail_cubit.dart';
import 'package:travel_advisor_mobile/features/city_detail/presentation/cubit/city_detail_state.dart';
import 'package:travel_advisor_mobile/features/city_detail/presentation/widgets/activity_vertical_card.dart';
import 'package:travel_advisor_mobile/features/city_detail/presentation/widgets/city_detail_cards.dart';
import 'package:travel_advisor_mobile/features/city_detail/presentation/widgets/city_detail_tab_bar.dart';
import 'package:travel_advisor_mobile/features/city_detail/presentation/widgets/filter_bottom_sheet.dart';
import 'package:travel_advisor_mobile/features/city_detail/presentation/widgets/hotel_vertical_card.dart';
import 'package:travel_advisor_mobile/features/city_detail/presentation/widgets/itinerary_vertical_card.dart';
import 'package:travel_advisor_mobile/features/city_detail/presentation/widgets/restaurant_vertical_card.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/cubit/itinerary_cubit.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/screens/itinerary_summary_screen.dart';
import 'package:travel_advisor_mobile/features/place/presentation/cubit/place_detail_cubit.dart';
import 'package:travel_advisor_mobile/features/place/presentation/screens/place_detail_screen.dart';
import 'package:travel_advisor_mobile/features/trip_planner/presentation/screens/trip_planner_screen.dart';

class CityDetailScreen extends StatelessWidget {
  final String cityName;
  final String cityId;

  const CityDetailScreen({
    super.key,
    required this.cityName,
    required this.cityId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CityDetailCubit>()..loadCityDetail(cityId, cityName),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            cityName,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: BlocBuilder<CityDetailCubit, CityDetailState>(
          builder: (context, state) {
            return state.when(
              initial: () => const SizedBox.shrink(),
              loading: () => const Center(child: CircularProgressIndicator()),
              loaded: (
                overview,
                activeTab,
                activityFilter,
                restaurantFilter,
                hotelFilter,
                filteredActivities,
                filteredRestaurants,
                filteredHotels,
                itineraries,
              ) =>
                  _CityDetailContent(
                    overview: overview,
                    activeTab: activeTab,
                    activityFilter: activityFilter,
                    restaurantFilter: restaurantFilter,
                    hotelFilter: hotelFilter,
                    filteredActivities: filteredActivities,
                    filteredRestaurants: filteredRestaurants,
                    filteredHotels: filteredHotels,
                    itineraries: itineraries,
                  ),
              error: (message) => Center(child: Text(message)),
            );
          },
        ),
        bottomNavigationBar: SharedBottomNav(
          currentIndex: 0,
          onTap: (i) {
            if (i == 2) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const TripPlannerScreen(),
                ),
              );
              return;
            }
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        ),
      ),
    );
  }
}

class _CityDetailContent extends StatefulWidget {
  final CityOverview overview;
  final int activeTab;
  final ActivityFilter activityFilter;
  final RestaurantFilter restaurantFilter;
  final HotelFilter hotelFilter;
  final List<CityActivity> filteredActivities;
  final List<CityRestaurant> filteredRestaurants;
  final List<CityHotel> filteredHotels;
  final List<CityItinerary> itineraries;

  const _CityDetailContent({
    required this.overview,
    required this.activeTab,
    required this.activityFilter,
    required this.restaurantFilter,
    required this.hotelFilter,
    required this.filteredActivities,
    required this.filteredRestaurants,
    required this.filteredHotels,
    required this.itineraries,
  });

  @override
  State<_CityDetailContent> createState() => _CityDetailContentState();
}

class _CityDetailContentState extends State<_CityDetailContent> {
  final PageController _itineraryController = PageController(viewportFraction: 0.88);
  final PageController _activityController = PageController(viewportFraction: 0.45);
  final PageController _restaurantController = PageController(viewportFraction: 0.45);
  final PageController _hotelController = PageController(viewportFraction: 0.45);

  int _itineraryIndex = 0;
  int _activityIndex = 0;
  int _restaurantIndex = 0;
  int _hotelIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: CityDetailTabBar(
            selectedIndex: widget.activeTab,
            onTabSelected: (index) {
              context.read<CityDetailCubit>().changeTab(index);
            },
          ),
        ),
        Expanded(
          child: widget.activeTab == 0
              ? _OverviewTabContent(
                  overviewItineraries: widget.itineraries.take(5).toList(),
                  overviewActivities: widget.filteredActivities.take(5).toList(),
                  overviewRestaurants: widget.filteredRestaurants.take(5).toList(),
                  overviewHotels: widget.filteredHotels.take(5).toList(),
                  itineraryController: _itineraryController,
                  activityController: _activityController,
                  restaurantController: _restaurantController,
                  hotelController: _hotelController,
                  itineraryIndex: _itineraryIndex,
                  activityIndex: _activityIndex,
                  restaurantIndex: _restaurantIndex,
                  hotelIndex: _hotelIndex,
                  onItineraryPageChanged: (i) => setState(() => _itineraryIndex = i),
                  onActivityPageChanged: (i) => setState(() => _activityIndex = i),
                  onRestaurantPageChanged: (i) => setState(() => _restaurantIndex = i),
                  onHotelPageChanged: (i) => setState(() => _hotelIndex = i),
                  onTabSelected: (index) => context.read<CityDetailCubit>().changeTab(index),
                )
              : widget.activeTab == 1
                  ? _ItineraryTabContent(itineraries: widget.itineraries)
                  : widget.activeTab == 2
                      ? _ActivityTabContent(
                          activities: widget.filteredActivities,
                          filter: widget.activityFilter,
                        )
                      : widget.activeTab == 3
                          ? _RestaurantTabContent(
                              restaurants: widget.filteredRestaurants,
                              filter: widget.restaurantFilter,
                            )
                          : widget.activeTab == 4
                              ? _HotelTabContent(
                                  hotels: widget.filteredHotels,
                                  filter: widget.hotelFilter,
                                )
                              : const Center(
                                  child: Text(
                                    'Nội dung cho Tab này đang được phát triển',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
        ),
      ],
    );
  }
}

class _OverviewTabContent extends StatelessWidget {
  final List<CityItinerary> overviewItineraries;
  final List<CityActivity> overviewActivities;
  final List<CityRestaurant> overviewRestaurants;
  final List<CityHotel> overviewHotels;
  final PageController itineraryController;
  final PageController activityController;
  final PageController restaurantController;
  final PageController hotelController;
  final int itineraryIndex;
  final int activityIndex;
  final int restaurantIndex;
  final int hotelIndex;
  final ValueChanged<int> onItineraryPageChanged;
  final ValueChanged<int> onActivityPageChanged;
  final ValueChanged<int> onRestaurantPageChanged;
  final ValueChanged<int> onHotelPageChanged;
  final ValueChanged<int> onTabSelected;

  const _OverviewTabContent({
    required this.overviewItineraries,
    required this.overviewActivities,
    required this.overviewRestaurants,
    required this.overviewHotels,
    required this.itineraryController,
    required this.activityController,
    required this.restaurantController,
    required this.hotelController,
    required this.itineraryIndex,
    required this.activityIndex,
    required this.restaurantIndex,
    required this.hotelIndex,
    required this.onItineraryPageChanged,
    required this.onActivityPageChanged,
    required this.onRestaurantPageChanged,
    required this.onHotelPageChanged,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final activityCardH   = screenW * 0.45 * (3 / 4) + 64;
    final restaurantCardH = screenW * 0.45 * (3 / 4) + 64;
    final hotelCardH      = screenW * 0.45 * (3 / 4) + 86;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const SizedBox(height: 20),

        // ── LỊCH TRÌNH CỘNG ĐỒNG ──────────────────────────────────
        SectionHeader(
          title: 'Gợi ý từ cộng đồng',
          onSeeAll: () => onTabSelected(1),
        ),
        const SizedBox(height: 12),
        if (overviewItineraries.isEmpty)
          const _SectionEmptyState(
            height: 140,
            message: 'Chưa có lịch trình cộng đồng cho tỉnh/thành phố này.',
          )
        else
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: SizedBox(
              height: screenW * 0.88 * (9 / 16) + 126,
              child: PageView.builder(
                controller: itineraryController,
                padEnds: false,
                clipBehavior: Clip.none,
                onPageChanged: onItineraryPageChanged,
                itemCount: overviewItineraries.length,
                itemBuilder: (context, index) {
                  final item = overviewItineraries[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider<ItineraryCubit>(
                              create: (_) {
                                final cubit = sl<ItineraryCubit>();
                                cubit.loadData().then((_) {
                                  cubit.selectItinerary(item.id);
                                });
                                return cubit;
                              },
                              child: ItinerarySummaryScreen(itineraryId: item.id),
                            ),
                          ),
                        );
                      },
                      child: ItineraryCard(item: item),
                    ),
                  );
                },
              ),
            ),
          ),
        const SizedBox(height: 4),
        PageDots(count: overviewItineraries.length, current: itineraryIndex),
        const SizedBox(height: 16),

        // ── HOẠT ĐỘNG THAM QUAN & GIẢI TRÍ ────────────────────────
        SectionHeader(
          title: 'Hoạt động tham quan & giải trí',
          onSeeAll: () => onTabSelected(2),
        ),
        const SizedBox(height: 12),
        if (overviewActivities.isEmpty)
          const _SectionEmptyState(
            height: 120,
            message: 'Chưa có hoạt động tham quan & giải trí cho tỉnh/thành phố này.',
          )
        else
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: SizedBox(
              height: activityCardH,
              child: PageView.builder(
                controller: activityController,
                padEnds: false,
                clipBehavior: Clip.none,
                onPageChanged: onActivityPageChanged,
                itemCount: overviewActivities.length,
                itemBuilder: (context, index) {
                  final item = overviewActivities[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider(
                              create: (_) => sl<PlaceDetailCubit>(),
                              child: PlaceDetailScreen(placeId: item.id),
                            ),
                          ),
                        );
                      },
                      child: ActivityCard(item: item),
                    ),
                  );
                },
              ),
            ),
          ),
        const SizedBox(height: 4),
        PageDots(count: overviewActivities.length, current: activityIndex),
        const SizedBox(height: 16),

        // ── NHÀ HÀNG TIÊU BIỂU ───────────────────────────────────
        SectionHeader(
          title: 'Nhà hàng tiêu biểu',
          onSeeAll: () => onTabSelected(3),
        ),
        const SizedBox(height: 12),
        if (overviewRestaurants.isEmpty)
          const _SectionEmptyState(
            height: 120,
            message: 'Chưa có nhà hàng tiêu biểu cho tỉnh/thành phố này.',
          )
        else
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: SizedBox(
              height: restaurantCardH,
              child: PageView.builder(
                controller: restaurantController,
                padEnds: false,
                clipBehavior: Clip.none,
                onPageChanged: onRestaurantPageChanged,
                itemCount: overviewRestaurants.length,
                itemBuilder: (context, index) {
                  final item = overviewRestaurants[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider(
                              create: (_) => sl<PlaceDetailCubit>(),
                              child: PlaceDetailScreen(placeId: item.id),
                            ),
                          ),
                        );
                      },
                      child: RestaurantCard(item: item),
                    ),
                  );
                },
              ),
            ),
          ),
        const SizedBox(height: 4),
        PageDots(count: overviewRestaurants.length, current: restaurantIndex),
        const SizedBox(height: 16),

        // ── KHÁCH SẠN & CHỖ Ở ────────────────────────────────────
        SectionHeader(
          title: 'Khách sạn & Chỗ ở',
          onSeeAll: () => onTabSelected(4),
        ),
        const SizedBox(height: 12),
        if (overviewHotels.isEmpty)
          const _SectionEmptyState(
            height: 120,
            message: 'Chưa có khách sạn hoặc chỗ ở cho tỉnh/thành phố này.',
          )
        else
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: SizedBox(
              height: hotelCardH,
              child: PageView.builder(
                controller: hotelController,
                padEnds: false,
                clipBehavior: Clip.none,
                onPageChanged: onHotelPageChanged,
                itemCount: overviewHotels.length,
                itemBuilder: (context, index) {
                  final item = overviewHotels[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider(
                              create: (_) => sl<PlaceDetailCubit>(),
                              child: PlaceDetailScreen(placeId: item.id),
                            ),
                          ),
                        );
                      },
                      child: HotelCard(item: item),
                    ),
                  );
                },
              ),
            ),
          ),
        const SizedBox(height: 4),
        PageDots(count: overviewHotels.length, current: hotelIndex),
        SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
      ],
    );
  }
}

class _ItineraryTabContent extends StatelessWidget {
  final List<CityItinerary> itineraries;
  const _ItineraryTabContent({required this.itineraries});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 16),
        ...itineraries.map(
          (item) => GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider<ItineraryCubit>(
                    create: (_) {
                      final cubit = sl<ItineraryCubit>();
                      cubit.loadData().then((_) {
                        cubit.selectItinerary(item.id);
                      });
                      return cubit;
                    },
                    child: ItinerarySummaryScreen(itineraryId: item.id),
                  ),
                ),
              );
            },
            child: ItineraryVerticalCard(item: item),
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }
}

class _FilterHeader extends StatelessWidget {
  final int resultCount;
  final String label;
  final bool hasActiveFilter;
  final VoidCallback onFilterTap;

  const _FilterHeader({
    required this.resultCount,
    required this.label,
    required this.hasActiveFilter,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$resultCount $label',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          GestureDetector(
            onTap: onFilterTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: hasActiveFilter
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.inputFill,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: hasActiveFilter ? AppColors.primary : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tune,
                    size: 16,
                    color: hasActiveFilter ? AppColors.primary : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Bộ lọc',
                    style: TextStyle(
                      fontSize: 13,
                      color: hasActiveFilter ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: hasActiveFilter ? FontWeight.w600 : FontWeight.normal,
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
}

class _ActivityTabContent extends StatelessWidget {
  final List<CityActivity> activities;
  final ActivityFilter filter;
  const _ActivityTabContent({required this.activities, required this.filter});

  bool get _hasActiveFilter =>
      filter.categories.isNotEmpty ||
      filter.priceType != ActivityPriceType.all ||
      filter.district != null ||
      filter.sortOption != SortOption.none;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 16),
        _FilterHeader(
          resultCount: activities.length,
          label: 'kết quả',
          hasActiveFilter: _hasActiveFilter,
          onFilterTap: () => _showFilterSheet(context),
        ),
        if (activities.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 60),
            child: Center(
              child: Text(
                'Không tìm thấy kết quả phù hợp',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 15),
              ),
            ),
          ),
        ...activities.map(
          (item) => GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) => sl<PlaceDetailCubit>(),
                    child: PlaceDetailScreen(placeId: item.id),
                  ),
                ),
              );
            },
            child: ActivityVerticalCard(item: item),
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ActivityFilterSheet(
        currentFilter: filter,
        onApply: (newFilter) {
          context.read<CityDetailCubit>().updateActivityFilter(newFilter);
        },
      ),
    );
  }
}

class _RestaurantTabContent extends StatelessWidget {
  final List<CityRestaurant> restaurants;
  final RestaurantFilter filter;
  const _RestaurantTabContent({required this.restaurants, required this.filter});

  bool get _hasActiveFilter =>
      filter.cuisines.isNotEmpty ||
      filter.priceLevel != RestaurantPriceLevel.all ||
      filter.amenities.isNotEmpty ||
      filter.sortOption != SortOption.none;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 16),
        _FilterHeader(
          resultCount: restaurants.length,
          label: 'kết quả',
          hasActiveFilter: _hasActiveFilter,
          onFilterTap: () => _showFilterSheet(context),
        ),
        if (restaurants.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 60),
            child: Center(
              child: Text(
                'Không tìm thấy kết quả phù hợp',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 15),
              ),
            ),
          ),
        ...restaurants.map(
          (item) => GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) => sl<PlaceDetailCubit>(),
                    child: PlaceDetailScreen(placeId: item.id),
                  ),
                ),
              );
            },
            child: RestaurantVerticalCard(item: item),
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RestaurantFilterSheet(
        currentFilter: filter,
        onApply: (newFilter) {
          context.read<CityDetailCubit>().updateRestaurantFilter(newFilter);
        },
      ),
    );
  }
}

class _HotelTabContent extends StatelessWidget {
  final List<CityHotel> hotels;
  final HotelFilter filter;
  const _HotelTabContent({required this.hotels, required this.filter});

  bool get _hasActiveFilter =>
      filter.minPrice > 0 ||
      filter.maxPrice > 0 ||
      filter.accommodationTypes.isNotEmpty ||
      filter.amenities.isNotEmpty ||
      filter.sortOption != SortOption.none;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 16),
        _FilterHeader(
          resultCount: hotels.length,
          label: 'kết quả',
          hasActiveFilter: _hasActiveFilter,
          onFilterTap: () => _showFilterSheet(context),
        ),
        if (hotels.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 60),
            child: Center(
              child: Text(
                'Không tìm thấy kết quả phù hợp',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 15),
              ),
            ),
          ),
        ...hotels.map(
          (item) => GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) => sl<PlaceDetailCubit>(),
                    child: PlaceDetailScreen(placeId: item.id),
                  ),
                ),
              );
            },
            child: HotelVerticalCard(item: item),
          ),
        ),
        SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
      ],
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HotelFilterSheet(
        currentFilter: filter,
        onApply: (newFilter) {
          context.read<CityDetailCubit>().updateHotelFilter(newFilter);
        },
      ),
    );
  }
}

class _SectionEmptyState extends StatelessWidget {
  final String message;
  final double height;

  const _SectionEmptyState({
    required this.message,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}