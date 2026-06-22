import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:travel_advisor_mobile/core/constants/app_sizes.dart';
import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/core/di/injection_container.dart';
import 'package:travel_advisor_mobile/core/services/activity_service.dart';
import 'package:travel_advisor_mobile/features/search/presentation/cubit/search_cubit.dart';
import 'package:travel_advisor_mobile/features/city_detail/presentation/screens/city_detail_screen.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/cubit/itinerary_cubit.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/screens/itinerary_summary_screen.dart';
import 'package:travel_advisor_mobile/features/itinerary/tracking/presentation/cubit/tracking_cubit.dart';
import 'package:travel_advisor_mobile/features/place/presentation/cubit/place_detail_cubit.dart';
import 'package:travel_advisor_mobile/features/place/presentation/screens/place_detail_screen.dart';
import 'package:travel_advisor_mobile/features/search/domain/entities/search_location.dart';

class SearchResultWidget extends StatelessWidget {
  final List<SearchLocation> results;
  final VoidCallback? onViewAll;

  static const _maxVisible = 10;

  const SearchResultWidget({
    super.key,
    required this.results,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 52, color: Colors.grey[300]),
            const SizedBox(height: 12),
            const Text(
              'Không tìm thấy kết quả phù hợp',
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),
          ],
        ),
      );
    }

    final visible = results.take(_maxVisible).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSizes.s16),
        const Text(
          'Tất cả kết quả',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: AppSizes.s16),
        Expanded(
          child: ListView.separated(
            itemCount: visible.length + 1,
            separatorBuilder: (_, index) => index < visible.length - 1
                ? const Divider(height: 1, indent: 72)
                : const SizedBox(height: AppSizes.s8),
            itemBuilder: (context, index) {
              if (index == visible.length) {
                return _ViewAllButton(onTap: onViewAll);
              }
              final location = visible[index];
              return InkWell(
                onTap: () => _onTap(context, location),
                child: _ResultItem(location: location),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _onTap(BuildContext context, SearchLocation location) async {
    if (location.type == 'place') {
      sl<ActivityService>().trackClick(location.id);
      sl<ActivityService>().trackSearchPlace(location.id);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => sl<PlaceDetailCubit>(),
            child: PlaceDetailScreen(placeId: location.id),
          ),
        ),
      );
    } else if (location.type == 'itinerary') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => sl<ItineraryCubit>()),
              BlocProvider(create: (_) => sl<TrackingCubit>()),
            ],
            child: ItinerarySummaryScreen(itineraryId: location.id),
          ),
        ),
      );
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CityDetailScreen(
            cityName: location.name,
            cityId: location.id,
          ),
        ),
      );
    }
    if (context.mounted) {
      context.read<SearchCubit>().loadRecentSearches(silent: true);
    }
  }
}

class _ResultItem extends StatelessWidget {
  final SearchLocation location;
  const _ResultItem({required this.location});

  @override
  Widget build(BuildContext context) {
    final IconData fallbackIcon;
    final String subtitle;
    switch (location.type) {
      case 'place':
        fallbackIcon = Icons.place_rounded;
        subtitle = 'Địa điểm';
      case 'itinerary':
        fallbackIcon = Icons.map_outlined;
        subtitle = 'Lịch trình';
      default:
        fallbackIcon = Icons.location_city_rounded;
        subtitle = 'Thành phố';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          _Thumbnail(imageUrl: location.imageUrl, fallbackIcon: fallbackIcon),
          const SizedBox(width: AppSizes.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 20),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final String imageUrl;
  final IconData fallbackIcon;

  const _Thumbnail({required this.imageUrl, required this.fallbackIcon});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) return _FallbackThumb(icon: fallbackIcon);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.r8),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        placeholder: (_, _) => const _ShimmerThumb(),
        errorWidget: (_, _, _) => _FallbackThumb(icon: fallbackIcon),
      ),
    );
  }
}

class _FallbackThumb extends StatelessWidget {
  final IconData icon;
  const _FallbackThumb({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(AppSizes.r8),
      ),
      child: Icon(icon, color: Colors.grey[400], size: 28),
    );
  }
}

class _ShimmerThumb extends StatefulWidget {
  const _ShimmerThumb();

  @override
  State<_ShimmerThumb> createState() => _ShimmerThumbState();
}

class _ShimmerThumbState extends State<_ShimmerThumb>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _colorAnimation = ColorTween(
      begin: Colors.grey[300],
      end: Colors.grey[100],
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (_, _) => Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: _colorAnimation.value,
          borderRadius: BorderRadius.circular(AppSizes.r8),
        ),
      ),
    );
  }
}

class _ViewAllButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _ViewAllButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'Xem tất cả kết quả',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
