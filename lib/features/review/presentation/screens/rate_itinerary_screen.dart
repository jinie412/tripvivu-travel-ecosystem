import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'place_review_screen.dart';

import 'package:travel_advisor_mobile/core/di/injection_container.dart';
import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/features/review/presentation/cubit/review_cubit.dart';
import 'package:travel_advisor_mobile/features/review/presentation/cubit/review_state.dart';
import 'package:travel_advisor_mobile/features/review/presentation/widgets/location_review_list_tile.dart';
import 'package:travel_advisor_mobile/features/review/presentation/widgets/review_itinerary_card.dart';

class RateItineraryScreen extends StatelessWidget {
  final String itineraryId;
  final bool isReadOnly;

  const RateItineraryScreen({
    super.key,
    required this.itineraryId,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ReviewCubit>()..loadReviewData(itineraryId),
      child: _RateItineraryView(isReadOnly: isReadOnly),
    );
  }
}

class _RateItineraryView extends StatelessWidget {
  final bool isReadOnly;
  const _RateItineraryView({required this.isReadOnly});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Nền màu xám cực nhạt như Figma
      appBar: AppBar(
        title: Text(
          'Đánh giá lịch trình',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C1C1E)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1C1C1E), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<ReviewCubit, ReviewState>(
        builder: (context, state) {
          if (state is ReviewLoading || state is ReviewInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ReviewError) {
            return Center(child: Text(state.message));
          }
          if (state is ReviewLoaded) {
            final filteredLocations = state.selectedDay == 0
                ? state.itinerary.locations
                : state.itinerary.locations
                    .where((l) => l.day == state.selectedDay)
                    .toList();

            return Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      ReviewItineraryCard(
                        itinerary: state.itinerary,
                        rating: state.generalRating,
                        applyToAll: state.applyToAllLocations,
                        mediaPaths: state.mediaPaths,
                        onRatingChanged: isReadOnly ? (_) {} : (rating) {
                          context.read<ReviewCubit>().setGeneralRating(rating);
                        },
                        onApplyToAllChanged: isReadOnly ? (_) {} : (value) {
                          context.read<ReviewCubit>().toggleApplyToAll(value);
                        },
                        onAddMedia: isReadOnly ? () {} : () {
                          context.read<ReviewCubit>().addMedia();
                        },
                        onRemoveMedia: isReadOnly ? (_) {} : (path) {
                          context.read<ReviewCubit>().removeMedia(path);
                        },
                        onClearAllMedia: isReadOnly ? () {} : () {
                          context.read<ReviewCubit>().clearAllMedia();
                        },
                      ),
                      const SizedBox(height: 32),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Đánh giá địa điểm',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1C1C1E),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.blobLight.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${state.itinerary.locations.length} địa điểm',
                                style: const TextStyle(
                                    fontSize: 10, color: Color(0xFF6B7280)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            _buildFilterChip(context, 'TẤT CẢ', 0, state.selectedDay),
                            _buildFilterChip(context, 'NGÀY 1', 1, state.selectedDay),
                            _buildFilterChip(context, 'NGÀY 2', 2, state.selectedDay),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...filteredLocations.map(
                        (loc) => LocationReviewListTile(
                          location: loc,
                          isReadOnly: isReadOnly,
                          onRatingChanged: isReadOnly ? (_) {} : (rating) {
                            context.read<ReviewCubit>().setLocationRating(loc.id, rating);
                          },
                          onWriteReview: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PlaceReviewScreen(
                                  locationId: loc.id,
                                  reviewCubit: context.read<ReviewCubit>(),
                                  isReadOnly: isReadOnly,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 100), // Padding cho nút bottom
                    ],
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 16,
                      bottom: MediaQuery.of(context).padding.bottom + 16,
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        minimumSize: const Size(double.infinity, 48),
                        elevation: 0,
                      ),
                      onPressed: isReadOnly ? () => Navigator.pop(context) : () {
                         // Thực hiện gửi đánh giá
                      },
                      child: Text(isReadOnly ? 'Quay lại' : 'Gửi đánh giá',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ),
                )
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildFilterChip(
      BuildContext context, String label, int day, int selectedDay) {
    final isSelected = day == selectedDay;
    return GestureDetector(
      onTap: () => context.read<ReviewCubit>().filterByDay(day),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.blobLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.primary,
          ),
        ),
      ),
    );
  }
}