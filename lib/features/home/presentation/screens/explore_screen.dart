import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/page_dots.dart';
import '../../../../core/widgets/section_header.dart';
import '../cubit/explore_cubit.dart';
import '../cubit/explore_state.dart';
import '../widgets/current_itinerary_card.dart';
import '../widgets/explore_header.dart';
import '../../../city_detail/presentation/widgets/city_detail_cards.dart' as city_cards;
import '../../../city_detail/domain/entities/city_entities.dart';
import '../widgets/home_itinerary_card.dart';
import '../../../city_detail/presentation/widgets/itinerary_vertical_card.dart';
import '../../../city_detail/presentation/widgets/activity_vertical_card.dart';
import '../../../city_detail/presentation/widgets/restaurant_vertical_card.dart';
import '../../../city_detail/presentation/widgets/hotel_vertical_card.dart';
import 'see_all_screen.dart';

import '../../../food/presentation/screens/food_menu_screen.dart';
import '../../../food/presentation/widgets/pre_order_popup.dart';
import '../../../review/presentation/widgets/itinerary_rating_popup.dart';

import '../../../place/presentation/screens/place_detail_screen.dart';
import '../../../place/presentation/cubit/place_detail_cubit.dart';
import '../../../itinerary/presentation/cubit/itinerary_cubit.dart';
import '../../../itinerary/presentation/screens/itinerary_summary_screen.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ExploreCubit>()..loadData(),
      child: const _ExploreView(),
    );
  }
}

class _ExploreView extends StatefulWidget {
  const _ExploreView();

  @override
  State<_ExploreView> createState() => _ExploreViewState();
}

class _ExploreViewState extends State<_ExploreView> {
  int _suggestionPage = 0;
  int _activityPage = 0;
  int _restaurantPage = 0;
  int _hotelPage = 0;
  bool _isItineraryStarted = false;

  void _onToggleItinerary(bool value) {
    setState(() => _isItineraryStarted = value);
    if (value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chế độ hành trình đã bật. Hệ thống sẽ tự động gợi ý món ăn khi bạn đến gần điểm dừng.'),
          duration: Duration(seconds: 3),
        ),
      );

      Future.delayed(const Duration(seconds: 4), () {
        if (!mounted || !_isItineraryStarted) return;
        _showPreOrderNotification();
      });
    }
  }

  void _showPreOrderNotification() {
    const restaurantName = 'Cơm tấm Ba Ghiền';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PreOrderPopup(
        restaurantName: restaurantName,
        onOrderTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FoodMenuScreen(restaurantName: restaurantName)),
          );
        },
      ),
    );

    Future.delayed(const Duration(seconds: 10), () {
      if (!mounted || !_isItineraryStarted) return;
      _showTripCompletionPopup();
    });
  }

  void _showTripCompletionPopup() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const ItineraryRatingPopup(
        itineraryId: 'itin-001',
        itineraryTitle: 'Sài Gòn 3N2Đ',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExploreCubit, ExploreState>(
      builder: (context, state) {
        if (state is ExploreLoading || state is ExploreInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is ExploreError) {
          return ErrorView(
            error: state.message,
            onRetry: () => context.read<ExploreCubit>().loadData(),
          );
        }
        if (state is ExploreLoaded) {
          return Column(
            children: [
              const ExploreHeader(),
              Expanded(child: _buildContent(context, state)),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildContent(BuildContext context, ExploreLoaded state) {
    return CustomScrollView(
      slivers: [
        if (state.currentItinerary != null)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
<<<<<<< HEAD
                const SizedBox(height: 20),
                // Section Header with View All
                SectionHeader(
                  title: 'Lịch trình của bạn', 
                  onSeeAll: null,
                ),
=======
                const SizedBox(height: 24),
                SectionHeader(title: 'Lịch trình của bạn', onSeeAll: null),
                const SizedBox(height: 16),
>>>>>>> 03ad165bfa9b8745fff76edecfa40438f833ed39
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CurrentItineraryCard(
                    item: state.currentItinerary,
                    isStarted: _isItineraryStarted,
                    onToggle: _onToggleItinerary,
                  ),
                ),
              ],
            ),
          ),

        // ── Lịch trình gợi ý ────────────────────────────────────────────────
        if (state.suggestions.isNotEmpty)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                SectionHeader(title: 'Lịch trình gợi ý', onSeeAll: () {
                  final items = state.suggestions.map((item) => CityItinerary(
                    id: item.id,
                    title: item.title,
                    authorName: 'Traveler',
                    authorAvatar: 'https://i.pravatar.cc/100?u=${item.id}',
                    imageUrl: item.imageUrl ?? '',
                    duration: item.days.toLowerCase(),
                    views: item.views,
                    likes: item.likes,
                  )).toList();
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => SeeAllScreen(
                      title: 'Lịch trình gợi ý',
                      items: items.map((item) => GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => BlocProvider<ItineraryCubit>(
                              create: (_) => sl<ItineraryCubit>()..loadData(),
                              child: ItinerarySummaryScreen(itineraryId: item.id),
                            ),
                          ));
                        },
                        child: ItineraryVerticalCard(item: item),
                      )).toList(),
                    ),
                  ));
                }),
                const SizedBox(height: 16),
                SizedBox(
                  height: 268,
                  child: PageView.builder(
                    controller: PageController(viewportFraction: 0.88),
                    padEnds: false,
                    clipBehavior: Clip.none,
                    itemCount: state.suggestions.length,
                    onPageChanged: (i) => setState(() => _suggestionPage = i),
                    itemBuilder: (_, i) {
                      final item = state.suggestions[i];
                      return Padding(
                        padding: EdgeInsets.only(left: i == 0 ? 16 : 0, right: 12),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => BlocProvider<ItineraryCubit>(
                                create: (_) => sl<ItineraryCubit>()..loadData(),
                                child: ItinerarySummaryScreen(itineraryId: item.id),
                              ),
                            ));
                          },
                          child: HomeItineraryCard(item: item),
                        ),
                      );
                    },
                  ),
                ),
                PageDots(count: state.suggestions.length, current: _suggestionPage),
              ],
            ),
          ),

        // ── Điểm đến nổi bật ─────────────────────────────────────────────
        if (state.destinations.isNotEmpty)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                SectionHeader(title: 'Điểm đến nổi bật', onSeeAll: () {
                  final items = state.destinations.map((item) => CityActivity(
                    id: item.id,
                    title: item.name,
                    imageUrl: item.imageUrl ?? '',
                    rating: 4.5,
                    reviewCount: 120,
                  )).toList();
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => SeeAllScreen(
                      title: 'Điểm đến nổi bật',
                      items: items.map((item) => GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => BlocProvider(
                              create: (_) => sl<PlaceDetailCubit>(),
                              child: PlaceDetailScreen(placeId: item.id),
                            ),
                          ));
                        },
                        child: ActivityVerticalCard(item: item),
                      )).toList(),
                    ),
                  ));
                }),
                const SizedBox(height: 16),
                SizedBox(
                  height: 168,
                  child: PageView.builder(
                    controller: PageController(viewportFraction: 0.35),
                    padEnds: false,
                    clipBehavior: Clip.none,
                    itemCount: state.destinations.length,
                    onPageChanged: (i) => setState(() => _activityPage = i),
                    itemBuilder: (_, i) {
                      final item = state.destinations[i];
                      return Padding(
                        padding: EdgeInsets.only(left: i == 0 ? 16 : 0, right: 12),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => BlocProvider(
                                create: (_) => sl<PlaceDetailCubit>(),
                                child: PlaceDetailScreen(placeId: item.id),
                              ),
                            ));
                          },
                          child: city_cards.ActivityCard(
                            item: CityActivity(
                              id: item.id,
                              title: item.name,
                              imageUrl: item.imageUrl ?? '',
                              rating: 4.5,
                              reviewCount: 120,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                PageDots(count: state.destinations.length, current: _activityPage),
              ],
            ),
          ),

        // ── Nhà hàng tiêu biểu ─────────────────────────────────────────────
        if (state.restaurants.isNotEmpty)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                SectionHeader(title: 'Nhà hàng tiêu biểu', onSeeAll: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => SeeAllScreen(
                      title: 'Nhà hàng tiêu biểu',
                      items: state.restaurants.map((item) => GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => BlocProvider(
                              create: (_) => sl<PlaceDetailCubit>(),
                              child: PlaceDetailScreen(placeId: item.id),
                            ),
                          ));
                        },
                        child: RestaurantVerticalCard(item: item),
                      )).toList(),
                    ),
                  ));
                }),
                const SizedBox(height: 16),
                SizedBox(
                  height: 185,
                  child: PageView.builder(
                    controller: PageController(viewportFraction: 0.45),
                    padEnds: false,
                    clipBehavior: Clip.none,
                    itemCount: state.restaurants.length,
                    onPageChanged: (i) => setState(() => _restaurantPage = i),
                    itemBuilder: (_, i) {
                      final item = state.restaurants[i];
                      return Padding(
                        padding: EdgeInsets.only(left: i == 0 ? 16 : 0, right: 12),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => BlocProvider(
                                create: (_) => sl<PlaceDetailCubit>(),
                                child: PlaceDetailScreen(placeId: item.id),
                              ),
                            ));
                          },
                          child: city_cards.RestaurantCard(item: item),
                        ),
                      );
                    },
                  ),
                ),
                PageDots(count: state.restaurants.length, current: _restaurantPage),
              ],
            ),
          ),

        // ── Khách sạn nổi bật ─────────────────────────────────────────────
        if (state.hotels.isNotEmpty)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                SectionHeader(title: 'Khách sạn nổi bật', onSeeAll: () {
                  final items = state.hotels.map((item) => CityHotel(
                    id: item.id,
                    name: item.name,
                    imageUrl: item.imageUrl ?? '',
                    rating: item.rating,
                    reviewCount: 350,
                    price: item.price,
                  )).toList();
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => SeeAllScreen(
                      title: 'Khách sạn nổi bật',
                      items: items.map((item) => GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => BlocProvider(
                              create: (_) => sl<PlaceDetailCubit>(),
                              child: PlaceDetailScreen(placeId: item.id),
                            ),
                          ));
                        },
                        child: HotelVerticalCard(item: item),
                      )).toList(),
                    ),
                  ));
                }),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: PageView.builder(
                    controller: PageController(viewportFraction: 0.65),
                    padEnds: false,
                    clipBehavior: Clip.none,
                    itemCount: state.hotels.length,
                    onPageChanged: (i) => setState(() => _hotelPage = i),
                    itemBuilder: (_, i) {
                      final item = state.hotels[i];
                      return Padding(
                        padding: EdgeInsets.only(left: i == 0 ? 16 : 0, right: 12),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => BlocProvider(
                                create: (_) => sl<PlaceDetailCubit>(),
                                child: PlaceDetailScreen(placeId: item.id),
                              ),
                            ));
                          },
                          child: city_cards.HotelCard(
                            item: CityHotel(
                              id: item.id,
                              name: item.name,
                              imageUrl: item.imageUrl ?? '',
                              rating: item.rating,
                              reviewCount: 350,
                              price: item.price,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                PageDots(count: state.hotels.length, current: _hotelPage),
              ],
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}



