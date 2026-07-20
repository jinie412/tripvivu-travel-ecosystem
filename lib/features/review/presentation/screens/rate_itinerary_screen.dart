import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'place_review_screen.dart';
import 'review_catalog_screen.dart'
    show
        ReviewedPlaceCard,
        openReviewedPlaceReview,
        reviewedPlaceItemFromSubmittedPlace;

import 'package:travel_advisor_mobile/core/di/injection_container.dart';
import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/features/review/domain/entities/review_types.dart';
import 'package:travel_advisor_mobile/features/review/presentation/constants/review_tags.dart'
    show getTagsForCategory;
import 'package:travel_advisor_mobile/features/review/presentation/cubit/review_cubit.dart';
import 'package:travel_advisor_mobile/features/review/presentation/cubit/review_state.dart';
import 'package:travel_advisor_mobile/features/review/presentation/utils/review_media_picker.dart';
import 'package:travel_advisor_mobile/features/review/presentation/widgets/location_review_list_tile.dart';
import 'package:travel_advisor_mobile/features/review/presentation/widgets/review_itinerary_card.dart';

class RateItineraryScreen extends StatelessWidget {
  final String itineraryId;
  final bool isReadOnly;
  final double initialRating;
  final String initialComment;
  final bool popExtraOnSubmit;
  final bool forceRefreshOnLoad;

  const RateItineraryScreen({
    super.key,
    required this.itineraryId,
    this.isReadOnly = false,
    this.initialRating = 0.0,
    this.initialComment = '',
    this.popExtraOnSubmit = true,
    this.forceRefreshOnLoad = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = sl<ReviewCubit>();
        if (isReadOnly) {
          cubit.loadSubmittedReview(itineraryId);
        } else {
          cubit.loadReviewData(
            itineraryId,
            initialRating: initialRating,
            initialComment: initialComment,
            forceRefresh: forceRefreshOnLoad,
          );
        }
        return cubit;
      },
      child: _RateItineraryView(
        itineraryId: itineraryId,
        isReadOnly: isReadOnly,
        popExtraOnSubmit: popExtraOnSubmit,
      ),
    );
  }
}

class _RateItineraryView extends StatelessWidget {
  final String itineraryId;
  final bool isReadOnly;
  final bool popExtraOnSubmit;
  const _RateItineraryView({
    required this.itineraryId,
    required this.isReadOnly,
    required this.popExtraOnSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.premiumBackground,
      appBar: AppBar(
        title: const Text(
          'Đánh giá lịch trình',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1C1C1E),
          ),
        ),
        backgroundColor: AppColors.premiumBackground,
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
                .where(
                  (location) =>
                      location.isVisited ||
                      location.hasReview ||
                      location.rating != null,
                )
                .toList();
            final filteredLocations = state.selectedDay == 0
                ? visitedLocations
                : visitedLocations
                      .where((location) => location.day == state.selectedDay)
                      .toList();
            final submittedPlacesByDetailId = {
              for (final place
                  in state.submittedReview?.places ??
                      const <SubmittedPlaceReview>[])
                if (place.itineraryDetailId.isNotEmpty)
                  place.itineraryDetailId: place,
            };

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        ReviewItineraryCard(
                          itinerary: state.itinerary,
                          rating: state.generalRating,
                          applyToAll: state.applyToAllLocations,
                          generalComment: state.generalComment,
                          selectedTags: state.generalTags,
                          mediaItems: state.itineraryMedia,
                          isReadOnly: isReadOnly,
                          onRatingChanged: (rating) {
                            context.read<ReviewCubit>().setGeneralRating(
                              rating,
                            );
                          },
                          onApplyToAllChanged: (value) {
                            context.read<ReviewCubit>().toggleApplyToAll(value);
                          },
                          onGeneralCommentChanged: (value) {
                            context.read<ReviewCubit>().setGeneralComment(
                              value,
                            );
                          },
                          onTagToggled: (tag) {
                            context.read<ReviewCubit>().toggleGeneralTag(tag);
                          },
                          onAddImages: () async {
                            await context.read<ReviewCubit>().addImages();
                          },
                          onAddVideo: () async {
                            try {
                              await context.read<ReviewCubit>().addVideo();
                            } on ReviewMediaSelectionException catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.message),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          onRemoveMedia: (mediaId) {
                            context.read<ReviewCubit>().removeMedia(mediaId);
                          },
                          onClearAllMedia: () {
                            context.read<ReviewCubit>().clearAllMedia();
                          },
                        ),
                        const SizedBox(height: 32),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
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
                        if (filteredLocations.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 24,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_off_outlined,
                                  size: 18,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    state.selectedDay == 0
                                        ? 'Bạn chưa ghé thăm địa điểm nào trong lịch trình này.'
                                        : 'Không có địa điểm nào được ghé thăm vào ngày ${state.selectedDay}.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade500,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ...filteredLocations.map((loc) {
                            final submittedPlace =
                                submittedPlacesByDetailId[loc.id];

                            // Places already reviewed — show same card as ReviewReadOnlyScreen
                            if (submittedPlace != null &&
                                (isReadOnly || loc.hasReview)) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: ReviewedPlaceCard(
                                  place: reviewedPlaceItemFromSubmittedPlace(
                                    submittedPlace,
                                    startDate:
                                        state.submittedReview?.startDate ?? '',
                                  ),
                                  itineraryTitle: state.itinerary.title,
                                ),
                              );
                            }

                            return LocationReviewListTile(
                              location: loc,
                              mediaItems:
                                  state.locationMediaByDetailId[loc.id] ??
                                  const [],
                              isVisited: loc.isVisited,
                              isReadOnly: isReadOnly || loc.hasReview,
                              onRatingChanged: isReadOnly || loc.hasReview
                                  ? null
                                  : (rating) {
                                      context
                                          .read<ReviewCubit>()
                                          .setLocationRating(loc.id, rating);
                                    },
                              onWriteReview: () async {
                                if (isReadOnly) {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PlaceReviewScreen(
                                        locationId: loc.id,
                                        reviewCubit: context
                                            .read<ReviewCubit>(),
                                        isReadOnly: true,
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (loc.hasReview) {
                                  await openReviewedPlaceReview(
                                    context,
                                    itineraryId: itineraryId,
                                    itineraryDetailId: loc.id,
                                    cachedData: state.submittedReview,
                                  );
                                  return;
                                }
                                if (!context.mounted) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PlaceReviewScreen(
                                      locationId: loc.id,
                                      reviewCubit: context.read<ReviewCubit>(),
                                      isReadOnly: false,
                                      reviewTags: getTagsForCategory(
                                        loc.categoryId,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          }),
                      ],
                    ),
                  ),
                ),
                Container(
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
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Cảm ơn bạn đã đánh giá!'),
                                  backgroundColor: Color(0xFF22C55E),
                                ),
                              );
                              if (context.mounted) {
                                Navigator.of(context).pop();
                                if (popExtraOnSubmit &&
                                    Navigator.of(context).canPop()) {
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
                    child: isReadOnly
                        ? const Text(
                            'Quay lai',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : state.isSubmitting
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
                        : const Text(
                            'Gửi đánh giá',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
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
        state.itinerary.locations.map((item) => item.day).toSet().toList()
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
