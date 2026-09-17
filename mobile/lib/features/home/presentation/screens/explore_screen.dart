import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:travel_advisor_mobile/core/di/injection_container.dart';
import 'package:travel_advisor_mobile/core/widgets/error_view.dart';
import 'package:travel_advisor_mobile/core/widgets/page_dots.dart';
import 'package:travel_advisor_mobile/core/widgets/section_header.dart';
import 'package:travel_advisor_mobile/features/city_detail/domain/entities/city_entities.dart';
import 'package:travel_advisor_mobile/features/city_detail/presentation/widgets/activity_vertical_card.dart';
import 'package:travel_advisor_mobile/features/city_detail/presentation/widgets/city_detail_cards.dart'
    as city_cards;
import 'package:travel_advisor_mobile/features/city_detail/presentation/widgets/hotel_vertical_card.dart';
import 'package:travel_advisor_mobile/features/city_detail/presentation/widgets/restaurant_vertical_card.dart';
import 'package:travel_advisor_mobile/features/home/presentation/cubit/explore_cubit.dart';
import 'package:travel_advisor_mobile/features/home/presentation/cubit/explore_state.dart';
import 'package:travel_advisor_mobile/features/home/presentation/cubit/location_cubit.dart';
import 'package:travel_advisor_mobile/features/home/presentation/screens/paginated_see_all_screen.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/destination.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/trip_suggestion.dart';
import 'package:travel_advisor_mobile/features/home/presentation/widgets/current_itinerary_card.dart';
import 'package:travel_advisor_mobile/features/home/presentation/widgets/explore_header.dart';
import 'package:travel_advisor_mobile/features/home/presentation/widgets/home_itinerary_card.dart';

import 'package:travel_advisor_mobile/features/food/presentation/screens/food_menu_screen.dart';
import 'package:travel_advisor_mobile/features/food/presentation/widgets/pre_order_popup.dart';
import 'package:travel_advisor_mobile/features/city_detail/presentation/screens/city_detail_screen.dart';

import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/cubit/itinerary_cubit.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/screens/itinerary_summary_screen.dart';
import 'package:travel_advisor_mobile/core/services/activity_service.dart';
import 'package:travel_advisor_mobile/core/widgets/visible_place_tracker.dart';
import 'package:travel_advisor_mobile/features/saved/data/datasources/favorite_remote_datasource.dart';
import 'package:travel_advisor_mobile/features/itinerary/tracking/presentation/cubit/tracking_cubit.dart';
import 'package:travel_advisor_mobile/features/itinerary/tracking/presentation/cubit/tracking_state.dart';
import 'package:travel_advisor_mobile/features/itinerary/tracking/presentation/widgets/stop_tracking_dialog.dart';
import 'package:travel_advisor_mobile/features/itinerary/tracking/presentation/widgets/tracking_permissions.dart';
import 'package:travel_advisor_mobile/features/itinerary/tracking/tracking_config.dart';
import 'package:travel_advisor_mobile/features/home/presentation/widgets/destination_card.dart';
import 'package:travel_advisor_mobile/features/place/presentation/cubit/place_detail_cubit.dart';
import 'package:travel_advisor_mobile/features/place/presentation/screens/place_detail_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // ExploreCubit là DI singleton (persist qua các lần chuyển tab) — phải
        // cấp bằng .value chứ không phải create(), vì BlocProvider(create: ...)
        // tự động gọi close() khi widget dispose (vd. khi logout xóa navigator
        // stack), làm "chết" singleton vĩnh viễn cho tới khi restart app.
        BlocProvider.value(value: sl<ExploreCubit>()),
        BlocProvider(create: (_) => sl<LocationCubit>()..fetchLocation()),
      ],
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
  static const int _pageSize = 10;
  StreamSubscription<FavoriteChangedEvent>? _favoriteSubscription;
  int _suggestionPage = 0;
  int _activityPage = 0;
  int _restaurantPage = 0;
  int _hotelPage = 0;

  @override
  void initState() {
    super.initState();
    context.read<ExploreCubit>().loadData();
    _favoriteSubscription = sl<FavoriteRemoteDataSource>().changes.listen((
      event,
    ) {
      if (!mounted) return;
      context.read<ExploreCubit>().applyFavoriteChange(event);
    });
  }

  @override
  void dispose() {
    _favoriteSubscription?.cancel();
    super.dispose();
  }

  Future<void> _onToggleItinerary(bool value, String itineraryId) async {
    final trackingCubit = context.read<TrackingCubit>();
    final itineraryCubit = context.read<ItineraryCubit>();
    ItineraryStatus statusAfterStop() {
      final exploreState = context.read<ExploreCubit>().state;
      final item = exploreState is ExploreLoaded
          ? exploreState.currentItinerary
          : null;
      final endDate = item?.endDate;
      if (endDate == null) return ItineraryStatus.uncompleted;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final endPlusOne = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
      ).add(const Duration(days: 1));
      return !today.isBefore(endPlusOne)
          ? ItineraryStatus.completed
          : ItineraryStatus.uncompleted;
    }

    if (!value) {
      final ok = await showStopTrackingDialog(context);
      if (!ok || !mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      // Truyền itineraryId để backend luôn được báo dừng, kể cả khi
      // TrackingCubit đã mất state (app khởi động lại, cache không còn).
      final backendUpdated = await trackingCubit.stop(itineraryId: itineraryId);
      if (!mounted) return;

      if (!backendUpdated) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Chưa thể dừng lịch trình, vui lòng kiểm tra kết nối mạng và thử lại.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final stoppedStatus = statusAfterStop();
      itineraryCubit.toggleItineraryStatus(
        itineraryId,
        false,
        stoppedStatus: stoppedStatus,
      );
      context.read<ExploreCubit>().updateCurrentItineraryStatus(
        itineraryId,
        stoppedStatus,
      );
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Đã dừng chuyến đi. Hẹn gặp lại bạn ở hành trình tiếp theo! 👋',
          ),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final perm = await TrackingPermissions.ensure();
    if (!mounted) return;
    if (perm != TrackingPermResult.granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TrackingPermissions.messageFor(perm)),
          action: perm == TrackingPermResult.deniedBackground
              ? SnackBarAction(label: 'Mở Cài đặt', onPressed: openAppSettings)
              : null,
        ),
      );
      return;
    }

    await trackingCubit.start(itineraryId: itineraryId, date: DateTime.now());
    if (!mounted || !trackingCubit.state.isActive) return;

    itineraryCubit.toggleItineraryStatus(itineraryId, true);
    context.read<ExploreCubit>().updateCurrentItineraryStatus(
      itineraryId,
      ItineraryStatus.ongoing,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Chế độ hành trình đã bật. Hệ thống sẽ tự động gợi ý món ăn khi bạn đến gần điểm dừng.',
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  ExploreLoaded? get _loadedState {
    final s = context.read<ExploreCubit>().state;
    return s is ExploreLoaded ? s : null;
  }

  Future<bool> _setPlaceFavorite(String placeId, bool isFavorite) async {
    try {
      await sl<FavoriteRemoteDataSource>().setPlaceFavorite(
        placeId,
        isFavorite,
      );
      if (!mounted) return true;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFavorite
                ? 'Đã lưu vào danh mục yêu thích'
                : 'Đã bỏ khỏi danh mục yêu thích',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return true;
    } catch (_) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa thể cập nhật yêu thích, vui lòng thử lại'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
  }

  Future<void> _setItineraryFavorite(
    String itineraryId,
    bool isFavorite,
  ) async {
    try {
      await sl<FavoriteRemoteDataSource>().setItineraryFavorite(
        itineraryId,
        isFavorite,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFavorite
                ? 'Đã lưu vào danh mục yêu thích'
                : 'Đã bỏ khỏi danh mục yêu thích',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa thể cập nhật yêu thích, vui lòng thử lại'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openSuggestionSeeAll() async {
    final initial = _loadedState?.suggestions ?? const <TripSuggestion>[];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaginatedSeeAllScreen<TripSuggestion>(
          title: 'Lịch trình nổi bật',
          itemCountLabel: 'lịch trình',
          pageSize: _pageSize,
          maxItems: 50,
          initialItems: initial,
          favoriteChanges: sl<FavoriteRemoteDataSource>().changes,
          favoriteMapper: (item, event) =>
              event.type == FavoriteTargetType.itinerary && event.id == item.id
              ? item.copyWith(isFavorite: event.isFavorite)
              : item,
          pageLoader: (page, limit) => context
              .read<ExploreCubit>()
              .loadSuggestionsPage(page: page, limit: limit),
          cityExtractor: (item) => item.location,
          travelTypeExtractor: (item) =>
              item.travelType.isEmpty ? null : item.travelType,
          sortOptions: [
            SortOption<TripSuggestion>(
              label: 'Phổ biến nhất (lượt tim)',
              compare: (a, b) => b.favoriteCount.compareTo(a.favoriteCount),
            ),
          ],
          itemBuilder: (context, item) => GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider<ItineraryCubit>(
                    create: (_) => sl<ItineraryCubit>()..loadData(),
                    child: ItinerarySummaryScreen(itineraryId: item.id),
                  ),
                ),
              );
            },
            child: HomeItineraryCard(
              item: item,
              onFavoriteChanged: (value) =>
                  _setItineraryFavorite(item.id, value),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openDestinationSeeAll() async {
    final initial = _loadedState?.destinations ?? const <Destination>[];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaginatedSeeAllScreen<Destination>(
          title: 'Điểm đến nổi bật',
          itemCountLabel: 'địa điểm',
          pageSize: _pageSize,
          initialItems: initial,
          separatorHeight: 0,
          pageLoader: (page, limit) => context
              .read<ExploreCubit>()
              .loadDestinationsPage(page: page, limit: limit),
          ratingExtractor: (item) => item.averageRating,
          sortOptions: [
            SortOption<Destination>(
              label: 'Rating giảm dần',
              compare: (a, b) => b.averageRating.compareTo(a.averageRating),
            ),
            SortOption<Destination>(
              label: 'Rating tăng dần',
              compare: (a, b) => a.averageRating.compareTo(b.averageRating),
            ),
            SortOption<Destination>(
              label: 'Lượt đánh giá giảm dần',
              compare: (a, b) => b.reviewCount.compareTo(a.reviewCount),
            ),
            SortOption<Destination>(
              label: 'Lượt đánh giá tăng dần',
              compare: (a, b) => a.reviewCount.compareTo(b.reviewCount),
            ),
            SortOption<Destination>(
              label: 'Tên A–Z',
              compare: (a, b) => a.name.compareTo(b.name),
            ),
            SortOption<Destination>(
              label: 'Tên Z–A',
              compare: (a, b) => b.name.compareTo(a.name),
            ),
          ],
          itemBuilder: (context, item) => GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      CityDetailScreen(cityId: item.id, cityName: item.name),
                ),
              );
            },
            child: ActivityVerticalCard(
              showFavorite: false,
              showLocationIcon: false,
              showDestinationStats: true,
              item: CityActivity(
                id: item.id,
                name: item.name,
                imageUrl: item.imageUrl ?? '',
                rating: item.averageRating,
                reviewCount: item.reviewCount,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openRestaurantSeeAll() async {
    final initial = _loadedState?.restaurants ?? const <CityRestaurant>[];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaginatedSeeAllScreen<CityRestaurant>(
          title: 'Nhà hàng tiêu biểu',
          itemCountLabel: 'địa điểm',
          pageSize: _pageSize,
          maxItems: 50,
          initialItems: initial,
          separatorHeight: 0,
          favoriteChanges: sl<FavoriteRemoteDataSource>().changes,
          favoriteMapper: (item, event) =>
              event.type == FavoriteTargetType.place && event.id == item.id
              ? item.copyWith(isFavorite: event.isFavorite)
              : item,
          pageLoader: (page, limit) => context
              .read<ExploreCubit>()
              .loadRestaurantsPage(page: page, limit: limit),
          cityExtractor: (item) =>
              item.address.trim().isEmpty ? null : item.address.trim(),
          ratingExtractor: (item) => item.rating,
          statusExtractor: (item) => item.status,
          sortOptions: [
            SortOption<CityRestaurant>(
              label: 'Tên A–Z',
              compare: (a, b) => a.name.compareTo(b.name),
            ),
            SortOption<CityRestaurant>(
              label: 'Đánh giá cao nhất',
              compare: (a, b) => b.rating.compareTo(a.rating),
            ),
            SortOption<CityRestaurant>(
              label: 'Số đánh giá nhiều nhất',
              compare: (a, b) => b.reviewCount.compareTo(a.reviewCount),
            ),
          ],
          itemBuilder: (context, item) => GestureDetector(
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
            child: RestaurantVerticalCard(
              item: item,
              onFavoriteChanged: (value) => _setPlaceFavorite(item.id, value),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openHotelSeeAll() async {
    final initial = _loadedState?.hotels ?? const <CityHotel>[];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaginatedSeeAllScreen<CityHotel>(
          title: 'Khách sạn nổi bật',
          itemCountLabel: 'địa điểm',
          pageSize: _pageSize,
          maxItems: 50,
          initialItems: initial,
          separatorHeight: 0,
          favoriteChanges: sl<FavoriteRemoteDataSource>().changes,
          favoriteMapper: (item, event) =>
              event.type == FavoriteTargetType.place && event.id == item.id
              ? item.copyWith(isFavorite: event.isFavorite)
              : item,
          pageLoader: (page, limit) => context
              .read<ExploreCubit>()
              .loadHotelsPage(page: page, limit: limit),
          cityExtractor: (item) =>
              item.address.trim().isEmpty ? null : item.address.trim(),
          ratingExtractor: (item) => item.rating,
          statusExtractor: (item) => item.status,
          priceExtractor: (item) => item.priceValue,
          sortOptions: [
            SortOption<CityHotel>(
              label: 'Tên A–Z',
              compare: (a, b) => a.name.compareTo(b.name),
            ),
            SortOption<CityHotel>(
              label: 'Đánh giá cao nhất',
              compare: (a, b) => b.rating.compareTo(a.rating),
            ),
            SortOption<CityHotel>(
              label: 'Số đánh giá nhiều nhất',
              compare: (a, b) => b.reviewCount.compareTo(a.reviewCount),
            ),
          ],
          itemBuilder: (context, item) => GestureDetector(
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
            child: HotelVerticalCard(
              item: item,
              onFavoriteChanged: (value) => _setPlaceFavorite(item.id, value),
            ),
          ),
        ),
      ),
    );
  }

  void _showFoodProximityPopupFromTracking(
    BuildContext ctx,
    TrackingState state,
  ) {
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
          ctx.read<TrackingCubit>().dismissNearbyRestaurant(detailId: detailId);
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
          ctx.read<TrackingCubit>().dismissNearbyRestaurant(detailId: detailId);
        },
      ),
    ).then((_) {
      if (ctx.mounted) {
        ctx.read<TrackingCubit>().dismissNearbyRestaurant(
          detailId: detailId,
          evaluateNext: true,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TrackingCubit, TrackingState>(
      listenWhen: (p, c) =>
          c.nearbyRestaurantName != null &&
          c.nearbyRestaurantName != p.nearbyRestaurantName,
      listener: (ctx, state) => _showFoodProximityPopupFromTracking(ctx, state),
      child: BlocBuilder<ExploreCubit, ExploreState>(
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
            return ColoredBox(
              color: const Color(0xFFF6F8FB),
              child: Column(
                children: [
                  const ExploreHeader(),
                  Expanded(
                    child: RefreshIndicator(
                      color: const Color(0xFF176BBD),
                      onRefresh: () =>
                          context.read<ExploreCubit>().loadData(refresh: true),
                      child: _buildContent(context, state),
                    ),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, ExploreLoaded state) {
    final screenW = MediaQuery.of(context).size.width;
    final suggestionCardH = screenW * 0.88 * (9 / 16) + 142;
    final destinationCardH = screenW * 0.40 / .78;
    // _PremiumPlaceCard bọc ngoài trừ mất 12 (padding phải của item) + 9*2
    // (padding trái/phải của Container) chiều rộng thực tế của ảnh bên trong.
    final cardImgW = screenW * 0.45 - 30;
    final restaurantCardH = cardImgW * (3 / 4) + 110;
    final hotelCardH = cardImgW * (3 / 4) + 130;
    final isCompletelyEmpty =
        state.currentItinerary == null &&
        state.suggestions.isEmpty &&
        state.destinations.isEmpty &&
        state.restaurants.isEmpty &&
        state.hotels.isEmpty;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (isCompletelyEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Chưa có nội dung khám phá. Kéo xuống để tải lại.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 15),
                ),
              ),
            ),
          ),
        if (state.currentItinerary != null)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 28),
                SectionHeader(
                  eyebrow: 'Đang diễn ra',
                  icon: Icons.route_rounded,
                  title: 'Lịch trình của bạn',
                  onSeeAll: null,
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: BlocBuilder<TrackingCubit, TrackingState>(
                    buildWhen: (p, c) =>
                        p.isActive != c.isActive ||
                        p.itineraryId != c.itineraryId,
                    builder: (context, trackingState) {
                      final currentId = state.currentItinerary?.id ?? '';
                      // Backend là nguồn trạng thái bền vững trong lúc
                      // TrackingCubit đang restore context sau khi mở app.
                      // Nếu chỉ đọc state thiết bị, switch sẽ tạm/tự tắt mỗi
                      // lần Explore refresh hoặc trước khi restore hoàn tất.
                      final backendStarted =
                          state.currentItinerary?.trackingActive == true ||
                          state.currentItinerary?.status ==
                              ItineraryStatus.ongoing;
                      final localStarted =
                          trackingState.isActive &&
                          trackingState.itineraryId == currentId;
                      final isStarted = backendStarted || localStarted;
                      return CurrentItineraryCard(
                        item: state.currentItinerary,
                        isStarted: isStarted,
                        onToggle: (v) => _onToggleItinerary(v, currentId),
                      );
                    },
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
                const SizedBox(height: 32),
                SectionHeader(
                  eyebrow: 'Cảm hứng du lịch',
                  icon: Icons.auto_awesome_rounded,
                  title: 'Lịch trình nổi bật',
                  onSeeAll: () => _openSuggestionSeeAll(),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.zero,
                  child: SizedBox(
                    height: suggestionCardH,
                    child: PageView.builder(
                      controller: PageController(viewportFraction: 0.96),
                      padEnds: true,
                      clipBehavior: Clip.none,
                      itemCount: state.suggestions.take(5).length,
                      onPageChanged: (i) => setState(() => _suggestionPage = i),
                      itemBuilder: (_, i) {
                        final item = state.suggestions[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 7),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BlocProvider<ItineraryCubit>(
                                    create: (_) =>
                                        sl<ItineraryCubit>()..loadData(),
                                    child: ItinerarySummaryScreen(
                                      itineraryId: item.id,
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: HomeItineraryCard(
                              item: item,
                              onFavoriteChanged: (value) =>
                                  _setItineraryFavorite(item.id, value),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                PageDots(
                  count: state.suggestions.take(5).length,
                  current: _suggestionPage,
                ),
              ],
            ),
          ),

        // ── Điểm đến nổi bật ─────────────────────────────────────────────
        if (state.destinations.isNotEmpty)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                SectionHeader(
                  eyebrow: 'Đi để nhớ',
                  icon: Icons.landscape_rounded,
                  title: 'Điểm đến nổi bật',
                  onSeeAll: () => _openDestinationSeeAll(),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: SizedBox(
                    height: destinationCardH,
                    child: PageView.builder(
                      controller: PageController(viewportFraction: 0.40),
                      padEnds: false,
                      clipBehavior: Clip.none,
                      itemCount: state.destinations.length,
                      onPageChanged: (i) => setState(() => _activityPage = i),
                      itemBuilder: (_, i) {
                        final item = state.destinations[i];
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CityDetailScreen(
                                    cityId: item.id,
                                    cityName: item.name,
                                  ),
                                ),
                              );
                            },
                            child: AbsorbPointer(
                              child: DestinationCard(item: item),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                PageDots(
                  count: state.destinations.length,
                  current: _activityPage,
                ),
              ],
            ),
          ),

        // ── Nhà hàng tiêu biểu ─────────────────────────────────────────────
        if (state.restaurants.isNotEmpty)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                SectionHeader(
                  eyebrow: 'Hương vị địa phương',
                  icon: Icons.restaurant_rounded,
                  title: 'Nhà hàng tiêu biểu',
                  onSeeAll: () => _openRestaurantSeeAll(),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: SizedBox(
                    height: restaurantCardH,
                    child: PageView.builder(
                      controller: PageController(viewportFraction: 0.45),
                      padEnds: false,
                      clipBehavior: Clip.none,
                      itemCount: state.restaurants.take(5).length,
                      onPageChanged: (i) => setState(() => _restaurantPage = i),
                      itemBuilder: (_, i) {
                        final item = state.restaurants[i];
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: VisiblePlaceTracker(
                            placeId: item.id,
                            child: GestureDetector(
                              onTap: () {
                                sl<ActivityService>().trackClick(item.id);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BlocProvider(
                                      create: (_) => sl<PlaceDetailCubit>(),
                                      child: PlaceDetailScreen(
                                        placeId: item.id,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              child: _PremiumPlaceCard(
                                child: city_cards.RestaurantCard(
                                  item: item,
                                  showFavorite: false,
                                  onFavoriteChanged: (value) =>
                                      _setPlaceFavorite(item.id, value),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                PageDots(
                  count: state.restaurants.take(5).length,
                  current: _restaurantPage,
                ),
              ],
            ),
          ),

        // ── Khách sạn nổi bật ─────────────────────────────────────────────
        if (state.hotels.isNotEmpty)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                SectionHeader(
                  eyebrow: 'Nghỉ dưỡng tinh tế',
                  icon: Icons.bed_rounded,
                  title: 'Khách sạn nổi bật',
                  onSeeAll: () => _openHotelSeeAll(),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: SizedBox(
                    height: hotelCardH,
                    child: PageView.builder(
                      controller: PageController(viewportFraction: 0.45),
                      padEnds: false,
                      clipBehavior: Clip.none,
                      itemCount: state.hotels.take(5).length,
                      onPageChanged: (i) => setState(() => _hotelPage = i),
                      itemBuilder: (_, i) {
                        final item = state.hotels[i];
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
                            child: _PremiumPlaceCard(
                              child: city_cards.HotelCard(
                                item: item,
                                showFavorite: false,
                                onFavoriteChanged: (value) =>
                                    _setPlaceFavorite(item.id, value),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                PageDots(
                  count: state.hotels.take(5).length,
                  current: _hotelPage,
                ),
              ],
            ),
          ),

        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
        ),
      ],
    );
  }
}

class _PremiumPlaceCard extends StatelessWidget {
  final Widget child;

  const _PremiumPlaceCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 9, 9, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7EDF3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF102A43).withValues(alpha: .08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      // Giới hạn textScale để cỡ chữ hệ thống lớn không làm tràn khung
      // chiều cao cố định của card trong carousel.
      child: MediaQuery(
        data: mediaQuery.copyWith(
          textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.15),
        ),
        child: child,
      ),
    );
  }
}
