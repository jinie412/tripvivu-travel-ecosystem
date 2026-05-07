import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';

import 'place_review_screen.dart';

import 'package:travel_advisor_mobile/core/di/injection_container.dart';
import 'package:travel_advisor_mobile/core/services/activity_service.dart';
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
      child: _RateItineraryView(
        itineraryId: itineraryId,
        isReadOnly: isReadOnly,
      ),
    );
  }
}

class _RateItineraryView extends StatelessWidget {
  final String itineraryId;
  final bool isReadOnly;
  const _RateItineraryView({
    required this.itineraryId,
    required this.isReadOnly,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF8F9FA,
      ), // Nền màu xám cực nhạt như Figma
      appBar: AppBar(
        title: Text(
          'Đánh giá lịch trình',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1C1C1E),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF1C1C1E),
            size: 20,
          ),
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
            final visitedLocations = state.itinerary.locations
                .where((location) => location.isVisited)
                .toList();
            final filteredLocations = state.selectedDay == 0
                ? visitedLocations
                : visitedLocations
                      .where((location) => location.day == state.selectedDay)
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
                        generalComment: state.generalComment,
                        mediaPaths: state.mediaPaths,
                        onRatingChanged: isReadOnly
                            ? (_) {}
                            : (rating) {
                                context.read<ReviewCubit>().setGeneralRating(
                                  rating,
                                );
                              },
                        onApplyToAllChanged: isReadOnly
                            ? (_) {}
                            : (value) {
                                context.read<ReviewCubit>().toggleApplyToAll(
                                  value,
                                );
                              },
                        onGeneralCommentChanged: isReadOnly
                            ? (_) {}
                            : (value) {
                                context.read<ReviewCubit>().setGeneralComment(
                                  value,
                                );
                              },
                        onAddMedia: isReadOnly
                            ? () {}
                            : () {
                                context.read<ReviewCubit>().addMedia();
                              },
                        onRemoveMedia: isReadOnly
                            ? (_) {}
                            : (path) {
                                context.read<ReviewCubit>().removeMedia(path);
                              },
                        onClearAllMedia: isReadOnly
                            ? () {}
                            : () {
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
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.blobLight.withValues(
                                  alpha: 0.3,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${visitedLocations.length}  địa điểm',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF6B7280),
                                ),
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
                          children: _buildDayFilterChips(context, state),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...filteredLocations.map(
                        (loc) => LocationReviewListTile(
                          location: loc,
                          isVisited: loc.isVisited,
                          isReadOnly: isReadOnly,
                          onRatingChanged: isReadOnly
                              ? (_) {}
                              : (rating) {
                                  context.read<ReviewCubit>().setLocationRating(
                                    loc.id,
                                    rating,
                                  );
                                  if (loc.placeId != null && loc.placeId!.isNotEmpty) {
                                    sl<ActivityService>().trackRating(loc.placeId!);
                                  }
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
                      onPressed: isReadOnly
                          ? () => Navigator.pop(context)
                          : state.isSubmitting
                          ? null
                          : () async {
                              try {
                                await context.read<ReviewCubit>().submitReview(
                                  itineraryId,
                                );
                                if (!context.mounted) {
                                  return;
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Cảm ơn bạn đã đánh giá!'),
                                    backgroundColor: Color(0xFF22C55E),
                                  ),
                                );
                                // Sau khi gửi thành công, quay về màn hình ban đầu (đóng cả trang đánh giá và dialog)
                                if (context.mounted) {
                                  Navigator.of(
                                    context,
                                  ).pop(); // Đóng RateItineraryScreen
                                  // Thêm một lần pop nữa để đóng ItineraryReviewDialog
                                  if (Navigator.of(context).canPop()) {
                                    Navigator.of(context).pop();
                                  }
                                }
                              } catch (e) {
                                if (!context.mounted) return;

                                String errorMessage =
                                    'Lỗi hệ thống, vui lòng thử lại sau.';
                                if (e is DioException) {
                                  if (e.response != null &&
                                      e.response?.data != null) {
                                    if (e.response?.data is Map) {
                                      final msg = e.response!.data['message'];
                                      if (msg is List) {
                                        errorMessage = msg.join(', ');
                                      } else {
                                        errorMessage =
                                            msg?.toString() ?? e.toString();
                                      }
                                    } else {
                                      errorMessage =
                                          e.response?.data.toString() ??
                                          e.toString();
                                    }
                                  } else {
                                    errorMessage = e.message ?? e.toString();
                                  }
                                } else {
                                  errorMessage = e.toString();
                                }

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(errorMessage),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                              }
                            },
                      child: state.isSubmitting && !isReadOnly
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              isReadOnly ? 'Quay lại' : 'Gửi đánh giá',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
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

  List<Widget> _buildDayFilterChips(BuildContext context, ReviewLoaded state) {
    final days =
        state.itinerary.locations
            .where((item) => item.isVisited)
            .map((item) => item.day)
            .toSet()
            .toList()
          ..sort();

    return [
      _buildFilterChip(context, 'TẤT CẢ', 0, state.selectedDay),
      ...days.map(
        (day) => _buildFilterChip(context, 'NGÀY $day', day, state.selectedDay),
      ),
    ];
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    int day,
    int selectedDay,
  ) {
    final isSelected = day == selectedDay;
    return GestureDetector(
      onTap: () => context.read<ReviewCubit>().filterByDay(day),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.blobLight.withValues(alpha: 0.3),
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
