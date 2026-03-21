import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/destination.dart';

import '../../../../core/widgets/net_image.dart';
import '../../../../core/di/injection_container.dart';
import '../../../place/presentation/screens/place_detail_screen.dart';
import '../../../place/presentation/cubit/place_detail_cubit.dart';

class DestinationCard extends StatelessWidget {
  final Destination item;

  const DestinationCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: NetImage(
                url: item.imageUrl,
                placeholderColor: item.placeholderColor,
                borderRadius: 16,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1C1C1E),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
