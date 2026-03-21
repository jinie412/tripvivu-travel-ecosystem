import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/page_dots.dart';
import '../../../../core/widgets/section_header.dart';
import '../cubit/explore_cubit.dart';
import '../cubit/explore_state.dart';
import '../widgets/current_itinerary_card.dart';
import '../widgets/destination_card.dart';
import '../widgets/explore_header.dart';
import '../widgets/hotel_card.dart';
import '../widgets/trip_card_widget.dart';


import '../../../food/presentation/screens/food_menu_screen.dart';
import '../../../food/presentation/widgets/pre_order_popup.dart';
import '../../../review/presentation/widgets/itinerary_rating_popup.dart';

import '../../../place/presentation/screens/place_detail_screen.dart';
import '../../../place/presentation/cubit/place_detail_cubit.dart';
import '../../../itinerary/presentation/cubit/itinerary_cubit.dart';
import '../widgets/detailed_place_card.dart';
import 'see_all_screen.dart';

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
  int _destPage = 0;
  bool _isItineraryStarted = false;

  void _onToggleItinerary(bool value) {
    setState(() => _isItineraryStarted = value);
    if (value) {
      // Simulate proximity trigger after 2 seconds
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

    // Simulate Trip Completion after 10 more seconds for demo
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
                const SizedBox(height: 20),
                // Section Header with View All
                SectionHeader(
                  title: 'Lịch trình của bạn', 
                  onSeeAll: null,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CurrentItineraryCard(
                    item: state.currentItinerary,
                    isStarted: _isItineraryStarted,
                    onToggle: _onToggleItinerary,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        // ── Gợi ý cho bạn ────────────────────────────────────────────────
        if (state.suggestions.isNotEmpty)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(title: 'Gợi ý cho bạn', onSeeAll: () {
                  final cubit = context.read<ItineraryCubit>();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => BlocProvider.value(
                    value: cubit,
                    child: SeeAllScreen(
                      title: 'Gợi ý cho bạn',
                      items: state.suggestions.map((item) => DetailedPlaceCard(
                        title: item.title,
                        rating: 4.8, 
                        reviews: item.likes,
                        imageUrl: item.imageUrl ?? '',
                        placeholderColor: item.placeholderColor,
                        info: '${item.days} • ${item.location} • Địa điểm du lịch',
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => BlocProvider(
                              create: (_) => sl<PlaceDetailCubit>(),
                              child: PlaceDetailScreen(placeId: item.id),
                            ),
                          ));
                        },
                      )).toList(),
                    ),
                  )));
                }),
                const SizedBox(height: 12),
                SizedBox(
                  height: 230,
                  child: PageView.builder(
                    controller: PageController(viewportFraction: 0.88),
                    padEnds: false,
                    clipBehavior: Clip.none,
                    itemCount: state.suggestions.length,
                    onPageChanged: (i) => setState(() => _suggestionPage = i),
                    itemBuilder: (_, i) => Padding(
                      padding: EdgeInsets.only(
                        left: i == 0 ? 16 : 0,
                        right: 12,
                      ),
                      child: TripCardWidget(item: state.suggestions[i]),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
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
                const SizedBox(height: 20),
                SectionHeader(title: 'Điểm đến nổi bật', onSeeAll: () {
                  final cubit = context.read<ItineraryCubit>();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => BlocProvider.value(
                    value: cubit,
                    child: SeeAllScreen(
                      title: 'Điểm đến nổi bật',
                      items: state.destinations.map((item) => DetailedPlaceCard(
                        title: item.name,
                        rating: 4.5, 
                        reviews: '1.2k',
                        imageUrl: item.imageUrl ?? '',
                        placeholderColor: item.placeholderColor,
                        info: 'Việt Nam • Địa điểm du lịch',
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => BlocProvider(
                              create: (_) => sl<PlaceDetailCubit>(),
                              child: PlaceDetailScreen(placeId: item.id),
                            ),
                          ));
                        },
                      )).toList(),
                    ),
                  )));
                }),
                const SizedBox(height: 12),
                SizedBox(
                  height: 140,
                  child: PageView.builder(
                    controller: PageController(viewportFraction: 0.31),
                    padEnds: false,
                    clipBehavior: Clip.none,
                    itemCount: state.destinations.length,
                    onPageChanged: (i) => setState(() => _destPage = i),
                    itemBuilder: (_, i) => Padding(
                      padding: EdgeInsets.only(
                        left: i == 0 ? 16 : 0,
                        right: 10,
                      ),
                      child: DestinationCard(item: state.destinations[i]),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                PageDots(count: state.destinations.length, current: _destPage),
              ],
            ),
          ),
        // ── Khách sạn nổi bật ─────────────────────────────────────────────
        if (state.hotels.isNotEmpty)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                SectionHeader(title: 'Khách sạn nổi bật', onSeeAll: () {
                  final cubit = context.read<ItineraryCubit>();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => BlocProvider.value(
                    value: cubit,
                    child: SeeAllScreen(
                      title: 'Khách sạn nổi bật',
                      items: state.hotels.map((h) => DetailedPlaceCard(
                        title: h.name,
                        rating: h.rating,
                        reviews: '850', 
                        imageUrl: h.imageUrl ?? '',
                        placeholderColor: h.placeholderColor,
                        info: 'Trung tâm • ${h.price} • Khách sạn',
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => BlocProvider(
                              create: (_) => sl<PlaceDetailCubit>(),
                              child: PlaceDetailScreen(placeId: h.id),
                            ),
                          ));
                        },
                      )).toList(),
                    ),
                  )));
                }),
                const SizedBox(height: 12),
                SizedBox(
                  height: 220,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: state.hotels.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (_, i) {
                      final h = state.hotels[i];
                      return SizedBox(
                        width: 160,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => BlocProvider(
                                create: (_) => sl<PlaceDetailCubit>(),
                                child: PlaceDetailScreen(placeId: h.id),
                              ),
                            ));
                          },
                          child: HotelCard(item: h),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}



