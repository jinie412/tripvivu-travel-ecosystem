import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:travel_advisor_mobile/core/di/injection_container.dart';
import 'package:travel_advisor_mobile/core/services/activity_service.dart';
import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/features/place/presentation/cubit/place_detail_cubit.dart';
import 'package:travel_advisor_mobile/features/place/presentation/cubit/place_detail_state.dart';
import 'package:travel_advisor_mobile/features/saved/data/datasources/favorite_remote_datasource.dart';
import 'package:travel_advisor_mobile/features/place/presentation/widgets/place_contact_section.dart';
import 'package:travel_advisor_mobile/features/place/presentation/widgets/place_description_section.dart';
import 'package:travel_advisor_mobile/features/place/presentation/widgets/place_gallery_section.dart';
import 'package:travel_advisor_mobile/features/place/presentation/widgets/place_header.dart';
import 'package:travel_advisor_mobile/features/place/presentation/widgets/place_info_section.dart';
import 'package:travel_advisor_mobile/features/place/presentation/widgets/place_review_section.dart';
import 'package:travel_advisor_mobile/features/place/presentation/widgets/related_places_section.dart';
import 'package:travel_advisor_mobile/core/widgets/map_bottom_sheet.dart';

class PlaceDetailScreen extends StatefulWidget {
  final String placeId;
  final bool showRelatedPlaces;

  const PlaceDetailScreen({
    super.key,
    required this.placeId,
    this.showRelatedPlaces = true,
  });

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  StreamSubscription<FavoriteChangedEvent>? _favoriteSubscription;

  final _activityService = sl<ActivityService>();
  Timer? _dwellTimer;
  bool _viewTracked = false;

  @override
  void initState() {
    super.initState();
    _favoriteSubscription = sl<FavoriteRemoteDataSource>().changes.listen((
      event,
    ) {
      if (!mounted ||
          event.type != FavoriteTargetType.place ||
          event.id != widget.placeId) {
        return;
      }

      context.read<PlaceDetailCubit>().syncFavoriteState(
        event.id,
        event.isFavorite,
      );
    });

    // Load data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlaceDetailCubit>().loadPlaceDetail(widget.placeId);
    });
  }

  void _startDwellTimer() {
    if (_viewTracked) return;
    _dwellTimer?.cancel();
    _dwellTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      _activityService.trackView(widget.placeId);
      _viewTracked = true;
    });
  }

  void _showCheckinDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xác nhận check-in', textAlign: TextAlign.center),
        content: const Text(
          'Bạn đang ở tại địa điểm này?',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _activityService.trackVisited(widget.placeId);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã check-in thành công!'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  @override
  void dispose() {
    _favoriteSubscription?.cancel();
    _dwellTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<PlaceDetailCubit, PlaceDetailState>(
        listener: (context, state) {
          if (state is PlaceDetailLoaded) {
            _startDwellTimer();
          }
        },
        builder: (context, state) {
          if (state is PlaceDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          }


          if (state is PlaceDetailError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context
                        
                        .read<PlaceDetailCubit>()
                        
                        .loadPlaceDetail(widget.placeId),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }


          if (state is PlaceDetailLoaded) {
            final place = state.placeDetail;
            return RefreshIndicator(
              onRefresh: () => context
                  .read<PlaceDetailCubit>()
                  .loadPlaceDetail(widget.placeId, refresh: true),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    PlaceHeader(
                      imageUrl: place.images.isNotEmpty
                          ? place.images[0]
                          : 'https://images.unsplash.com/photo-1583417319070-4a69db38a482?w=800&q=80',
                      isFavorite: place.isFavorite,
                      onBack: () => Navigator.pop(context),
                      onFavorite: () async {
                        final result = await context
                            .read<PlaceDetailCubit>()
                            .toggleFavorite();
                        if (!context.mounted) return;
                        if (result == true) {
                          _activityService.trackSave(widget.placeId);
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã lưu vào danh mục yêu thích'),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } else if (result == false) {
                          _activityService.trackUnsave(widget.placeId);
                        } else {
                          // result == null: API error, state already reverted
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Không thể cập nhật yêu thích. Vui lòng thử lại.'),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),

                    // 2. Title, Rating, Location, Vibes
                    PlaceInfoSection(
                      name: place.name,
                      rating: place.rating,
                      location: '${place.district}, ${place.city}',
                      vibes: place.vibes,
                      onLocationTap: () => _showMap(
                        context,
                        place.latitude ?? 10.7766,
                        place.longitude ?? 106.7032,
                        place.name,
                        place.address,
                      ),
                    ),

                    // 3. Image Gallery
                    PlaceGallerySection(images: place.images),

                    // 4. Description
                    PlaceDescriptionSection(description: place.description),

                    // 5. Contact Info (Hours, Phone, Address)
                    PlaceContactSection(
                      openHourCompressed: place.openHourCompressed,
                      phone: place.phone,
                      address: place.address,
                      onLocationTap: () => _showMap(
                        context,
                        place.latitude ?? 10.7766,
                        place.longitude ?? 106.7032,
                        place.name,
                        place.address,
                      ),
                    ),

                    // 6. Reviews Section
                    PlaceReviewSection(
                      rating: place.rating,
                      totalReviews: place.totalReviews,
                      reviews: place.reviews,
                    ),

                    // 7. Related Places - ONLY SHOW if showRelatedPlaces is true
                    if (widget.showRelatedPlaces)
                      RelatedPlacesSection(relatedPlaces: place.relatedPlaces),

                    const SizedBox(height: 60),
                  ],
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _showMap(
    BuildContext context,
    double lat,
    double lng,
    String title,
    String address,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MapBottomSheet(
        latitude: lat,
        longitude: lng,
        name: title,
        address: address,
      ),
    );
  }
}
