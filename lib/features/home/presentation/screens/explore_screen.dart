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
import 'package:travel_advisor_mobile/features/food/data/datasources/food_remote_data_source.dart';
import 'package:travel_advisor_mobile/features/review/domain/repositories/review_repository.dart';
import 'package:travel_advisor_mobile/features/review/presentation/widgets/itinerary_rating_popup.dart';
import 'package:travel_advisor_mobile/features/city_detail/presentation/screens/city_detail_screen.dart';

import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/cubit/itinerary_cubit.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/screens/itinerary_summary_screen.dart';
import 'package:travel_advisor_mobile/core/services/activity_service.dart';
import 'package:travel_advisor_mobile/core/widgets/visible_place_tracker.dart';
import 'package:travel_advisor_mobile/features/saved/data/datasources/favorite_remote_datasource.dart';
import 'package:travel_advisor_mobile/features/itinerary/tracking/presentation/cubit/tracking_cubit.dart';
import 'package:travel_advisor_mobile/features/itinerary/tracking/presentation/cubit/tracking_state.dart';
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
        BlocProvider(create: (_) => sl<ExploreCubit>()..loadData()),
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
  List<OrderEligiblePlace> _orderPlaces = const [];
  int _currentOrderPlaceIndex = 0;
  bool _isLoadingOrderPlaces = false;

  bool get _isTrackingActive {
    if (!mounted) return false;
    return context.read<TrackingCubit>().state.isActive;
  }

  @override
  void initState() {
    super.initState();
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
      final endPlusOne = DateTime(endDate.year, endDate.month, endDate.day)
          .add(const Duration(days: 1));
      return !today.isBefore(endPlusOne)
          ? ItineraryStatus.completed
          : ItineraryStatus.uncompleted;
    }

    if (!value) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Dừng theo dõi?'),
          content: const Text(
            'Geofence sẽ được gỡ và không tự đánh dấu địa điểm nữa.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Huỷ'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Dừng'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
      await trackingCubit.stop();
      if (!mounted) return;
      final stoppedStatus = statusAfterStop();
      itineraryCubit.toggleItineraryStatus(
        itineraryId,
        false,
        stoppedStatus: stoppedStatus,
      );
      context
          .read<ExploreCubit>()
          .updateCurrentItineraryStatus(itineraryId, stoppedStatus);
      _orderPlaces = const [];
      _currentOrderPlaceIndex = 0;
      return;
    }

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

    await trackingCubit.start(
      itineraryId: itineraryId,
      date: DateTime.now(),
    );
    if (!mounted || !trackingCubit.state.isActive) return;

    itineraryCubit.toggleItineraryStatus(itineraryId, true);
    context
        .read<ExploreCubit>()
        .updateCurrentItineraryStatus(itineraryId, ItineraryStatus.ongoing);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Chế độ hành trình đã bật. Hệ thống sẽ tự động gợi ý món ăn khi bạn đến gần điểm dừng.',
        ),
        duration: Duration(seconds: 3),
      ),
    );

    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted || !_isTrackingActive) return;
      _showNextPreOrderNotification();
    });
  }

  Future<void> _prepareOrderPlaces() async {
    if (_isLoadingOrderPlaces || _orderPlaces.isNotEmpty) {
      return;
    }

    final exploreState = context.read<ExploreCubit>().state;
    if (exploreState is! ExploreLoaded ||
        exploreState.currentItinerary == null) {
      return;
    }

    _isLoadingOrderPlaces = true;
    try {
      final places = await sl<FoodRemoteDataSource>().getItineraryOrderPlaces(
        itineraryId: exploreState.currentItinerary!.id,
      );

      _orderPlaces = places;
      _currentOrderPlaceIndex = 0;
    } catch (_) {
      _orderPlaces = const [];
      _currentOrderPlaceIndex = 0;
    } finally {
      _isLoadingOrderPlaces = false;
    }
  }

  Future<void> _showNextPreOrderNotification() async {
    await _prepareOrderPlaces();
    if (!mounted || !_isTrackingActive) {
      return;
    }

    if (_currentOrderPlaceIndex >= _orderPlaces.length) {
      Future.delayed(const Duration(seconds: 6), () {
        if (!mounted || !_isTrackingActive) return;
        _showTripCompletionPopup();
      });
      return;
    }

    final currentPlace = _orderPlaces[_currentOrderPlaceIndex];

    OrderPopupData popupData;
    try {
      popupData = await sl<FoodRemoteDataSource>().getOrderPopup(
        currentPlace.placeId,
      );
    } catch (_) {
      popupData = OrderPopupData(
        placeId: currentPlace.placeId,
        placeName: currentPlace.placeName,
        title: 'Gợi ý cho bạn',
        message:
            'Bạn có muốn đặt trước món ăn để không phải chờ đợi khi đến nơi?',
        estimatedWaitMinutes: 20,
        rating: 0,
        reviewCount: 0,
      );
    }

    if (!mounted || !_isTrackingActive) {
      return;
    }

    bool movedToNext = false;
    void moveNext() {
      if (movedToNext) {
        return;
      }
      movedToNext = true;
      _currentOrderPlaceIndex += 1;
      Future.delayed(const Duration(seconds: 4), () {
        if (!mounted || !_isTrackingActive) {
          return;
        }
        _showNextPreOrderNotification();
      });
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PreOrderPopup(
        title: popupData.title,
        message: popupData.message,
        restaurantName: popupData.placeName,
        estimatedWaitMinutes: popupData.estimatedWaitMinutes,
        rating: popupData.rating,
        reviewCount: popupData.reviewCount,
        onOrderTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FoodMenuScreen(
                placeId: popupData.placeId,
                restaurantName: popupData.placeName,
                itineraryDetailId: currentPlace.itineraryDetailId,
              ),
            ),
          ).then((_) => moveNext());
        },
        onSkipTap: () {
          Navigator.pop(context);
          moveNext();
        },
      ),
    );

    if (!movedToNext) {
      moveNext();
    }
  }

  void _showTripCompletionPopup() {
    final exploreState = context.read<ExploreCubit>().state;
    if (exploreState is! ExploreLoaded ||
        exploreState.currentItinerary == null) {
      return;
    }

    final itinerary = exploreState.currentItinerary!;

    sl<ReviewRepository>()
        .getPopupData(itinerary.id)
        .then((popupData) {
          if (!mounted || !popupData.showPopup) {
            return;
          }

          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (context) => ItineraryRatingPopup(
              itineraryId: popupData.itineraryId,
              itineraryTitle: popupData.itineraryTitle,
            ),
          );
        })
        .catchError((_) {});
  }

  ExploreLoaded? get _loadedState {
    final s = context.read<ExploreCubit>().state;
    return s is ExploreLoaded ? s : null;
  }

  Future<void> _setPlaceFavorite(String placeId, bool isFavorite) async {
    try {
      await sl<FavoriteRemoteDataSource>().setPlaceFavorite(
        placeId,
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
          title: 'Lịch trình gợi ý',
          pageSize: _pageSize,
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
          pageSize: _pageSize,
          initialItems: initial,
          separatorHeight: 12,
          pageLoader: (page, limit) => context
              .read<ExploreCubit>()
              .loadDestinationsPage(page: page, limit: limit),
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
          pageSize: _pageSize,
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
          pageSize: _pageSize,
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
          ctx.read<TrackingCubit>().dismissNearbyRestaurant();
          Navigator.push(
            ctx,
            MaterialPageRoute(
              builder: (_) =>
                  FoodMenuScreen(placeId: placeId, restaurantName: name, itineraryDetailId: detailId),
            ),
          );
        },
        onSkipTap: () {
          Navigator.pop(ctx);
          ctx.read<TrackingCubit>().dismissNearbyRestaurant();
        },
      ),
    ).then((_) {
      if (ctx.mounted) ctx.read<TrackingCubit>().dismissNearbyRestaurant();
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
          return Column(
            children: [
              const ExploreHeader(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () =>
                      context.read<ExploreCubit>().loadData(refresh: true),
                  child: _buildContent(context, state),
                ),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
      ),
    );
  }

  Widget _buildContent(BuildContext context, ExploreLoaded state) {
    final screenW = MediaQuery.of(context).size.width;
    final suggestionCardH = screenW * 0.88 * (9 / 16) + 126;
    final destinationCardH = screenW * 0.35 * (1 / 1) + 64;
    final restaurantCardH = screenW * 0.45 * (3 / 4) + 80;
    final hotelCardH = screenW * 0.45 * (3 / 4) + 100;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (state.currentItinerary != null)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                SectionHeader(title: 'Lịch trình của bạn', onSeeAll: null),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: BlocBuilder<TrackingCubit, TrackingState>(
                    buildWhen: (p, c) =>
                        p.isActive != c.isActive ||
                        p.itineraryId != c.itineraryId,
                    builder: (context, trackingState) {
                      final currentId = state.currentItinerary?.id ?? '';
                      final isStarted = trackingState.isActive &&
                          trackingState.itineraryId == currentId;
                      return CurrentItineraryCard(
                        item: state.currentItinerary,
                        isStarted: isStarted,
                        onToggle: (v) =>
                            _onToggleItinerary(v, currentId),
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
                const SizedBox(height: 24),
                SectionHeader(
                  title: 'Lịch trình gợi ý',
                  onSeeAll: () => _openSuggestionSeeAll(),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: SizedBox(
                  height: suggestionCardH,
                  child: PageView.builder(
                    controller: PageController(viewportFraction: 0.88),
                    padEnds: false,
                    clipBehavior: Clip.none,
                    itemCount: state.suggestions.take(5).length,
                    onPageChanged: (i) => setState(() => _suggestionPage = i),
                    itemBuilder: (_, i) {
                      final item = state.suggestions[i];
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
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
                const SizedBox(height: 24),
                SectionHeader(
                  title: 'Điểm đến nổi bật',
                  onSeeAll: () => _openDestinationSeeAll(),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: SizedBox(
                  height: destinationCardH,
                  child: PageView.builder(
                    controller: PageController(viewportFraction: 0.35),
                    padEnds: false,
                    clipBehavior: Clip.none,
                    itemCount: state.destinations.take(5).length,
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
                PageDots(
                  count: state.destinations.take(5).length,
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
                const SizedBox(height: 24),
                SectionHeader(
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
                                      child: PlaceDetailScreen(placeId: item.id),
                                    ),
                                  ),
                                );
                              },
                              child: city_cards.RestaurantCard(
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
                const SizedBox(height: 4),
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
                const SizedBox(height: 24),
                SectionHeader(
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
                            child: city_cards.HotelCard(
                              item: item,
                              showFavorite: false,
                              onFavoriteChanged: (value) =>
                                  _setPlaceFavorite(item.id, value),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
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
