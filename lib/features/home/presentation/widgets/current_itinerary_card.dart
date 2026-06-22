import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:travel_advisor_mobile/core/di/injection_container.dart';
import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/cubit/itinerary_cubit.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/screens/itinerary_summary_screen.dart';

class CurrentItineraryCard extends StatelessWidget {
  final ItineraryEntity? item;

  final bool isStarted;
  final ValueChanged<bool>? onToggle;

  const CurrentItineraryCard({
    super.key,
    this.item,
    this.isStarted = false,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (item == null) {
      return const SizedBox.shrink(); // Hide if no current itinerary
    }

    final fmtMonth = DateFormat(
      'MMM',
      'vi_VN',
    ).format(item!.startDate ?? DateTime.now()).toUpperCase();
    final fmtDay =
        '${item!.startDate?.day ?? ''} \u2013 ${item!.endDate?.day ?? ''}';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider<ItineraryCubit>(
              create: (_) => sl<ItineraryCubit>()..loadData(),
              child: ItinerarySummaryScreen(itineraryId: item!.id),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.blobLight.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    fmtMonth,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    fmtDay,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (onToggle != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'BẮT ĐẦU LỊCH TRÌNH',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 24,
                          child: Transform.scale(
                            scale: 0.7,
                            child: Switch(
                              value: isStarted,
                              onChanged: onToggle,
                              activeThumbColor: const Color(0xFF2563EB),
                              activeTrackColor: const Color(0xFFBFDBFE),
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (onToggle != null) const SizedBox(height: 8),
                  Text(
                    item!.status == ItineraryStatus.upcoming
                        ? 'SẮP DIỄN RA'
                        : (item!.status == ItineraryStatus.completed
                              ? 'HOÀN THÀNH'
                              : 'ĐANG DIỄN RA'),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item!.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C1C1E),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.people_outline,
                        size: 12,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${item!.durationDays} ngày',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
