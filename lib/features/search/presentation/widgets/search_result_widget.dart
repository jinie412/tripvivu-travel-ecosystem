import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:travel_advisor_mobile/core/constants/app_sizes.dart';
import 'package:travel_advisor_mobile/core/di/injection_container.dart';
import 'package:travel_advisor_mobile/features/city_detail/presentation/screens/city_detail_screen.dart';
import 'package:travel_advisor_mobile/features/place/presentation/cubit/place_detail_cubit.dart';
import 'package:travel_advisor_mobile/features/place/presentation/screens/place_detail_screen.dart';
import 'package:travel_advisor_mobile/features/search/domain/entities/search_location.dart';

class SearchResultWidget extends StatelessWidget {
  final List<SearchLocation> results;

  const SearchResultWidget({
    super.key,
    required this.results,
  });

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const Center(
        child: Text(
          'Không tìm thấy kết quả phù hợp',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black54,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSizes.s16),
        Text(
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
            itemCount: results.length,
            itemBuilder: (context, index) {
              final location = results[index];
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
                    placeholder: (context, url) => Container(
                      width: 56,
                      height: 56,
                      color: Colors.grey[200],
                    ),
                    errorWidget: (context, url, error) =>
                        _fallbackThumb(fallbackIcon),
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