import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/page_dots.dart';
import '../../../../core/widgets/section_header.dart';
import '../../domain/entities/city_entities.dart';
import '../cubit/city_detail_cubit.dart';
import '../cubit/city_detail_state.dart';
import '../widgets/city_detail_cards.dart';
import '../widgets/city_detail_tab_bar.dart';
import '../widgets/activity_vertical_card.dart';
import '../widgets/hotel_vertical_card.dart';
import '../widgets/itinerary_vertical_card.dart';
import '../widgets/restaurant_vertical_card.dart';

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
      create: (_) => sl<CityDetailCubit>()..loadCityDetail(cityId),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
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
              loaded: (overview, activeTab) => _CityDetailContent(overview: overview, activeTab: activeTab),
              error: (message) => Center(child: Text(message)),
            );
          },
        ),
        bottomNavigationBar: const _SharedBottomNav(),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 28),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }
}

class _CityDetailContent extends StatefulWidget {
  final CityOverview overview;
  final int activeTab;
  const _CityDetailContent({required this.overview, required this.activeTab});

  @override
  State<_CityDetailContent> createState() => _CityDetailContentState();
}

class _CityDetailContentState extends State<_CityDetailContent> {
  final PageController _itineraryController = PageController(viewportFraction: 0.88);
  final PageController _activityController = PageController(viewportFraction: 0.45);
  final PageController _restaurantController = PageController(viewportFraction: 0.45);
  final PageController _hotelController = PageController(viewportFraction: 0.55);

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
            onTabSelected: (index) => context.read<CityDetailCubit>().changeTab(index),
          ),
        ),
        Expanded(
          child: widget.activeTab == 0
              ? _OverviewTabContent(
                  overview: widget.overview,
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
                  ? _ItineraryTabContent(itineraries: widget.overview.itineraries)
                  : widget.activeTab == 2
                      ? _ActivityTabContent(activities: widget.overview.activities)
                      : widget.activeTab == 3
                          ? _RestaurantTabContent(restaurants: widget.overview.restaurants)
                          : widget.activeTab == 4
                              ? _HotelTabContent(hotels: widget.overview.hotels)
                              : Center(
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
  final CityOverview overview;
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
    required this.overview,
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
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const SizedBox(height: 20),
        SectionHeader(title: 'Lịch trình cộng đồng', onSeeAll: () => onTabSelected(1)),
        const SizedBox(height: 12),
        SizedBox(
          height: 280, // Tăng lên 280 để chứa được tiêu đề 2 dòng + metadata (180+10+40+~30)
          child: PageView.builder(
            controller: itineraryController,
            padEnds: false,
            clipBehavior: Clip.none,
            onPageChanged: onItineraryPageChanged,
            itemCount: overview.itineraries.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 16 : 0,
                  right: 12,
                ),
                child: ItineraryCard(item: overview.itineraries[index]),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        PageDots(
          count: overview.itineraries.length,
          current: itineraryIndex,
        ),
        const SizedBox(height: 16),
        SectionHeader(title: 'Hoạt động tham quan', onSeeAll: () => onTabSelected(2)),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: activityController,
            padEnds: false,
            clipBehavior: Clip.none,
            onPageChanged: onActivityPageChanged,
            itemCount: overview.activities.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 16 : 0,
                  right: 12,
                ),
                child: ActivityCard(item: overview.activities[index]),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        PageDots(
          count: overview.activities.length,
          current: activityIndex,
        ),
        const SizedBox(height: 16),
        SectionHeader(title: 'Nhà hàng tiêu biểu', onSeeAll: () => onTabSelected(3)),
        const SizedBox(height: 12),
        SizedBox(
          height: 185,
          child: PageView.builder(
            controller: restaurantController,
            padEnds: false,
            clipBehavior: Clip.none,
            onPageChanged: onRestaurantPageChanged,
            itemCount: overview.restaurants.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 16 : 0,
                  right: 12,
                ),
                child: RestaurantCard(item: overview.restaurants[index]),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        PageDots(
          count: overview.restaurants.length,
          current: restaurantIndex,
        ),
        const SizedBox(height: 16),
        SectionHeader(title: 'Khách sạn & Chỗ ở', onSeeAll: () => onTabSelected(4)),
        const SizedBox(height: 12),
        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: hotelController,
            padEnds: false,
            clipBehavior: Clip.none,
            onPageChanged: onHotelPageChanged,
            itemCount: overview.hotels.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 16 : 0,
                  right: 12,
                ),
                child: HotelCard(item: overview.hotels[index]),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        PageDots(
          count: overview.hotels.length,
          current: hotelIndex,
        ),
        const SizedBox(height: 100),
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
        const SizedBox(height: 16), // Giữ khoảng cách trên cùng
        ...itineraries.map((item) => ItineraryVerticalCard(item: item)),
        const SizedBox(height: 100),
      ],
    );
  }
}

class _SharedBottomNav extends StatelessWidget {
  const _SharedBottomNav();

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Colors.white,
      elevation: 8,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(icon: Icons.explore_outlined, label: 'Khám phá', isActive: true),
            _buildNavItem(icon: Icons.map_outlined, label: 'Lịch trình', isActive: false),
            const SizedBox(width: 56), // Notch gap
            _buildNavItem(icon: Icons.favorite_outline, label: 'Đã lưu', isActive: false),
            _buildNavItem(icon: Icons.person_outline, label: 'Cá nhân', isActive: false),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, bool isActive = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: isActive ? AppColors.primary : Colors.grey, size: 24),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? AppColors.primary : Colors.grey,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _ActivityTabContent extends StatelessWidget {
  final List<CityActivity> activities;
  const _ActivityTabContent({required this.activities});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 16),
        ...activities.map((item) => ActivityVerticalCard(item: item)),
        const SizedBox(height: 100),
      ],
    );
  }
}

class _RestaurantTabContent extends StatelessWidget {
  final List<CityRestaurant> restaurants;
  const _RestaurantTabContent({required this.restaurants});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 16),
        ...restaurants.map((item) => RestaurantVerticalCard(item: item)),
        const SizedBox(height: 100),
      ],
    );
  }
}

class _HotelTabContent extends StatelessWidget {
  final List<CityHotel> hotels;
  const _HotelTabContent({required this.hotels});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 16),
        ...hotels.map((item) => HotelVerticalCard(item: item)),
        const SizedBox(height: 100),
      ],
    );
  }
}
