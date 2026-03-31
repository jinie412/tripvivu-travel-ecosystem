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
        // Hint Section
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
                      text: 'Tìm kiếm những địa điểm để khám phá hoặc thêm vào chuyến đi của bạn',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.s32),

        // Recent Searches Title
        Text(
          'Các tìm kiếm gần đây',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: AppSizes.s16),

        // Recent Searches List
        Expanded(
          child: ListView.builder(
            itemCount: recentSearches.length,
            itemBuilder: (context, index) {
              final location = recentSearches[index];
              return InkWell(
                onTap: () {
                  if (location.type == 'place') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider(
                          create: (_) => sl<PlaceDetailCubit>(),
                          child: PlaceDetailScreen(placeId: location.id),
                        ),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CityDetailScreen(
                          cityName: location.name,
                          cityId: location.id,
                        ),
                      ),
                    );
                  }
                },
                child: _buildRecentItem(location.name, location.imageUrl),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentItem(String title, String imageUrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.s20),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.r8),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              placeholder: (context, url) => const _ShimmerSkeleton(
                width: 56,
                height: 56,
              ),
              errorWidget: (context, url, error) => const _ShimmerSkeleton(
                width: 56,
                height: 56,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.s16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

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
      builder: (context, child) {
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