import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:travel_advisor_mobile/core/constants/app_sizes.dart';
import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/core/di/injection_container.dart';
import 'package:travel_advisor_mobile/features/city_detail/presentation/screens/city_detail_screen.dart';
import 'package:travel_advisor_mobile/features/place/presentation/cubit/place_detail_cubit.dart';
import 'package:travel_advisor_mobile/features/place/presentation/screens/place_detail_screen.dart';
import 'package:travel_advisor_mobile/features/search/domain/entities/search_location.dart';

class SearchResultWidget extends StatelessWidget {
  final List<SearchLocation> results;
  /// Gọi khi user bấm "Xem tất cả"
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
      return const Center(
        child: Text(
          'Không tìm thấy kết quả phù hợp',
          style: TextStyle(fontSize: 16, color: Colors.black54),
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
          child: ListView.builder(
            itemCount: visible.length + 1, // +1 cho nút "Xem tất cả"
            itemBuilder: (context, index) {
              if (index == visible.length) {
                return _ViewAllButton(onTap: onViewAll);
              }
              final location = visible[index];
              return InkWell(
                onTap: () => _onTap(context, location),
                child: _buildResultItem(
                  location.name,
                  location.imageUrl,
                  location.type,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _onTap(BuildContext context, SearchLocation location) {
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
  }

  Widget _buildResultItem(String title, String imageUrl, String type) {
    final fallbackIcon = type == 'city' ? Icons.location_city : Icons.place;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.s20),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.r8),
            child: imageUrl.isEmpty
                ? _fallbackThumb(fallbackIcon)
                : CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    placeholder: (ctx, url) => Container(
                      width: 56,
                      height: 56,
                      color: Colors.grey[200],
                    ),
                    errorWidget: (ctx, url, err) => _fallbackThumb(fallbackIcon),
                  ),
          ),
          const SizedBox(width: AppSizes.s16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        ],
      ),
    );
  }

  Widget _fallbackThumb(IconData icon) {
    return Container(
      width: 56,
      height: 56,
      color: Colors.grey[200],
      child: Icon(icon, color: Colors.grey[500]),
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
