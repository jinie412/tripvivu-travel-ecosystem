import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:travel_advisor_mobile/core/constants/app_sizes.dart';
import 'package:travel_advisor_mobile/core/di/injection_container.dart';
import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/features/city_detail/presentation/screens/city_detail_screen.dart';
import 'package:travel_advisor_mobile/features/place/presentation/cubit/place_detail_cubit.dart';
import 'package:travel_advisor_mobile/features/place/presentation/screens/place_detail_screen.dart';
import 'package:travel_advisor_mobile/features/search/domain/entities/search_location.dart';
import 'package:travel_advisor_mobile/features/search/presentation/cubit/search_cubit.dart';

class SearchSuggestionWidget extends StatelessWidget {
  final List<SearchLocation> recentSearches;

  const SearchSuggestionWidget({
    super.key,
    required this.recentSearches,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSizes.s8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.auto_awesome,
              color: AppColors.primary,
              size: AppSizes.iconDefault,
            ),
            const SizedBox(width: AppSizes.s8),
            Expanded(
              child: Text.rich(
                const TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                  children: [
                    TextSpan(
                      text: 'Hint: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text:
                          'Tìm kiếm những địa điểm để khám phá hoặc thêm vào chuyến đi của bạn',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.s32),

        Row(
          children: [
            const Expanded(
              child: Text(
                'Các tìm kiếm gần đây',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            Text(
              'Kéo xuống để làm mới',
              style: TextStyle(fontSize: 11, color: Colors.grey[400]),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.s16),

        Expanded(
          child: RefreshIndicator(
            onRefresh: () =>
                context.read<SearchCubit>().loadRecentSearches(silent: true),
            color: AppColors.primary,
            displacement: 20,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (recentSearches.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyRecentSearches(),
                  )
                else
                  SliverList.separated(
                    itemCount: recentSearches.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, indent: 72),
                    itemBuilder: (itemCtx, index) {
                      final location = recentSearches[index];
                      return _RecentSearchItem(
                        location: location,
                        onNavigated: () {
                          if (context.mounted) {
                            context
                                .read<SearchCubit>()
                                .loadRecentSearches(silent: true);
                          }
                        },
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _RecentSearchItem extends StatelessWidget {
  final SearchLocation location;
  final VoidCallback onNavigated;

  const _RecentSearchItem({
    required this.location,
    required this.onNavigated,
  });

  Future<void> _onTap(BuildContext context) async {
    if (location.type == 'place') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => sl<PlaceDetailCubit>(),
            child: PlaceDetailScreen(placeId: location.id),
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
    if (context.mounted) onNavigated();
  }

  @override
  Widget build(BuildContext context) {
    final isPlace = location.type == 'place';

    return InkWell(
      onTap: () => _onTap(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            _Thumbnail(imageUrl: location.imageUrl, type: location.type),
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
                    isPlace ? 'Địa điểm' : 'Thành phố',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Thumbnail extends StatelessWidget {
  final String imageUrl;
  final String type;

  const _Thumbnail({required this.imageUrl, required this.type});

  @override
  Widget build(BuildContext context) {
    final fallbackIcon =
        type == 'place' ? Icons.place_rounded : Icons.location_city_rounded;

    if (imageUrl.isEmpty) {
      return _FallbackThumb(icon: fallbackIcon);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.r8),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        placeholder: (_, _) => const _ShimmerSkeleton(width: 56, height: 56),
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

class _EmptyRecentSearches extends StatelessWidget {
  const _EmptyRecentSearches();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_rounded, size: 52, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            'Chưa có tìm kiếm gần đây',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Khám phá và tìm kiếm địa điểm bên dưới',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ShimmerSkeleton extends StatefulWidget {
  final double width;
  final double height;

  const _ShimmerSkeleton({
    required this.width,
    required this.height,
  });

  @override
  State<_ShimmerSkeleton> createState() => _ShimmerSkeletonState();
}

class _ShimmerSkeletonState extends State<_ShimmerSkeleton>
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
      builder: (_, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: _colorAnimation.value,
            borderRadius: BorderRadius.circular(AppSizes.r8),
          ),
        );
      },
    );
  }
}
