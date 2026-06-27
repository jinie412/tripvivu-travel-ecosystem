import 'package:flutter/material.dart';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:travel_advisor_mobile/core/di/injection_container.dart';
import 'package:travel_advisor_mobile/core/services/activity_service.dart';
import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/core/widgets/net_image.dart';
import 'package:travel_advisor_mobile/features/review/domain/entities/review_media_item.dart';
import 'package:travel_advisor_mobile/features/review/presentation/constants/review_tags.dart'
    show kDefaultReviewTags;
import 'package:travel_advisor_mobile/features/review/presentation/cubit/review_cubit.dart';
import 'package:travel_advisor_mobile/features/review/presentation/cubit/review_state.dart';
import 'package:travel_advisor_mobile/features/review/presentation/utils/review_media_picker.dart';
import 'package:travel_advisor_mobile/features/review/presentation/widgets/review_media_list.dart';
import 'package:travel_advisor_mobile/features/review/presentation/widgets/star_rating_input.dart';

class PlaceReviewScreen extends StatefulWidget {
  final String locationId;
  final ReviewCubit reviewCubit;
  final bool isReadOnly;
  final List<String> reviewTags;
  final bool submitOnSave;
  final String? itineraryId;

  const PlaceReviewScreen({
    super.key,
    required this.locationId,
    required this.reviewCubit,
    this.isReadOnly = false,
    this.reviewTags = kDefaultReviewTags,
    this.submitOnSave = false,
    this.itineraryId,
  });

  @override
  State<PlaceReviewScreen> createState() => _PlaceReviewScreenState();
}

class _PlaceReviewScreenState extends State<PlaceReviewScreen> {
  late double _rating;
  late TextEditingController _reviewController;
  late List<ReviewMediaItem> _mediaItems;
  late List<String> _selectedTags;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final state = widget.reviewCubit.state;
    if (state is ReviewLoaded) {
      final loc = state.itinerary.locations.firstWhere(
        (l) => l.id == widget.locationId,
      );
      _rating = loc.rating ?? 0.0;
      _reviewController = TextEditingController(text: loc.reviewText ?? '');
      _mediaItems = List<ReviewMediaItem>.from(
        state.locationMediaByDetailId[widget.locationId] ?? const [],
      );
      _selectedTags = List<String>.from(loc.reviewTags ?? []);
    } else {
      _rating = 0.0;
      _reviewController = TextEditingController();
      _mediaItems = [];
      _selectedTags = [];
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  String _visitDateLabel(ReviewLoaded state, int day) {
    final startRaw = state.submittedReview?.startDate ?? '';
    final start = DateTime.tryParse(startRaw);
    if (start != null) {
      final visitDate = start.add(Duration(days: day - 1));
      final d = visitDate.day.toString().padLeft(2, '0');
      final m = visitDate.month.toString().padLeft(2, '0');
      return 'Ngày $day · $d/$m/${visitDate.year}';
    }
    return 'Ngày $day';
  }

  String _getRatingText(double rating) {
    if (rating >= 5) return 'Tuyệt vời';
    if (rating >= 4) return 'Rất tốt';
    if (rating >= 3) return 'Bình thường';
    if (rating >= 2) return 'Tệ';
    if (rating >= 1) return 'Rất tệ';
    return '';
  }

  String _formatSubmitError(Object error) {
    if (error is DioException) {
      final responseData = error.response?.data;
      if (responseData is Map) {
        final message = responseData['message'];
        if (message is List && message.isNotEmpty) {
          return message.map((item) => item.toString()).join('\n');
        }
        if (message != null && message.toString().trim().isNotEmpty) {
          return message.toString();
        }
        final errorText = responseData['error'];
        if (errorText != null && errorText.toString().trim().isNotEmpty) {
          return errorText.toString();
        }
      }
      if (responseData != null && responseData.toString().trim().isNotEmpty) {
        return responseData.toString();
      }
      return 'Kh\u00f4ng th\u1ec3 g\u1eedi \u0111\u00e1nh gi\u00e1. Vui l\u00f2ng th\u1eed l\u1ea1i.';
    }
    return error.toString();
  }

  Future<void> _pickImages() async {
    final pickedMedia = await ReviewMediaPicker.pickImages(
      startSortOrder: _mediaItems.length,
    );
    if (pickedMedia.isNotEmpty) {
      setState(() {
        _mediaItems.addAll(pickedMedia);
      });
    }
  }

  Future<void> _pickVideo() async {
    String? preparingVideoId;
    try {
      final pickedVideo = await ReviewMediaPicker.pickVideo(
        sortOrder: _mediaItems.length,
        onPreparingVideo: (item) {
          preparingVideoId = item.id;
          if (!mounted) {
            return;
          }
          setState(() {
            final existingIndex = _mediaItems.indexWhere(
              (mediaItem) => mediaItem.id == item.id,
            );
            if (existingIndex >= 0) {
              _mediaItems[existingIndex] = item;
            } else {
              _mediaItems.add(item);
            }
          });
        },
      );

      if (pickedVideo != null) {
        setState(() {
          final existingIndex = _mediaItems.indexWhere(
            (item) => item.id == pickedVideo.id,
          );
          if (existingIndex >= 0) {
            _mediaItems[existingIndex] = pickedVideo;
          } else {
            _mediaItems.add(pickedVideo);
          }
        });
      }
    } on ReviewMediaSelectionException catch (error) {
      if (preparingVideoId != null && mounted) {
        setState(() {
          _mediaItems.removeWhere((item) => item.id == preparingVideoId);
        });
      }
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    if (widget.submitOnSave && _rating <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn số sao trước khi gửi'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Lấy placeId thực sự của POI trước khi cập nhật state
    String? placeId;
    final cubitState = widget.reviewCubit.state;
    if (cubitState is ReviewLoaded) {
      final idx = cubitState.itinerary.locations.indexWhere(
        (l) => l.id == widget.locationId,
      );
      if (idx != -1) placeId = cubitState.itinerary.locations[idx].placeId;
    }
    widget.reviewCubit.updateLocationReviewDetails(
      locationId: widget.locationId,
      rating: _rating > 0 ? _rating : null,
      reviewText: _reviewController.text,
      reviewTags: _selectedTags,
      mediaItems: _mediaItems,
    );
    if (placeId != null && placeId.isNotEmpty) {
      final activityService = sl<ActivityService>();
      if (_rating > 0) {
        activityService.trackRating(placeId);
      }
      if (_reviewController.text.trim().isNotEmpty) {
        activityService.trackReview(placeId);
      }
    }

    if (widget.submitOnSave && widget.itineraryId != null) {
      setState(() => _isSubmitting = true);
      try {
        await widget.reviewCubit.submitSinglePlaceReview(
          itineraryId: widget.itineraryId!,
          locationId: widget.locationId,
        );
        if (!mounted) return;
        Navigator.pop(context, true);
      } catch (e) {
        final message = _formatSubmitError(e);
        if (e is DioException) {
          debugPrint(
            '[PlaceReview] submitSinglePlaceReview failed: '
            '${e.requestOptions.method} ${e.requestOptions.uri} '
            'status=${e.response?.statusCode} '
            'request=${e.requestOptions.data} '
            'response=${e.response?.data}',
          );
        } else {
          debugPrint('[PlaceReview] submitSinglePlaceReview error: $e');
        }
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('L\u1ed7i: $message'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 8),
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReviewCubit, ReviewState>(
      bloc: widget.reviewCubit,
      builder: (context, state) {
        if (state is! ReviewLoaded) return const Scaffold();

        final location = state.itinerary.locations.firstWhere(
          (l) => l.id == widget.locationId,
        );

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.textPrimary,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              widget.isReadOnly ? 'Chi tiết đánh giá' : 'Viết đánh giá',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            actions: [
              if (!widget.isReadOnly)
                TextButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Gửi',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 60,
                          height: 60,
                          child: NetImage(
                            url: location.imageUrl,
                            placeholderColor: AppColors.blobLight.toARGB32(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              location.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 12,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _visitDateLabel(state, location.day),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
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
                const SizedBox(height: 32),
                const Center(
                  child: Text(
                    'Bạn cảm thấy địa điểm này thế nào?',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: StarRatingInput(
                    rating: _rating,
                    onRatingChanged: widget.isReadOnly
                        ? (_) {}
                        : (val) {
                            setState(() => _rating = val);
                          },
                    size: 32,
                    mainAxisAlignment: MainAxisAlignment.center,
                    enabled: !widget.isReadOnly,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _getRatingText(_rating),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: TextField(
                    controller: _reviewController,
                    maxLines: 5,
                    readOnly: widget.isReadOnly,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Chia sẻ trải nghiệm của bạn...',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ReviewMediaList(
                  mediaItems: _mediaItems,
                  onAddImages: widget.isReadOnly ? () {} : _pickImages,
                  onAddVideo: widget.isReadOnly ? () {} : _pickVideo,
                  onRemoveMedia: widget.isReadOnly
                      ? (_) {}
                      : (mediaId) {
                          setState(
                            () => _mediaItems.removeWhere(
                              (item) => item.id == mediaId,
                            ),
                          );
                        },
                  onClearAllMedia: widget.isReadOnly
                      ? () {}
                      : () {
                          setState(() => _mediaItems.clear());
                        },
                  imageSize: 80,
                ),
                if (!widget.isReadOnly || _selectedTags.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    widget.isReadOnly ? 'Từ khóa đánh giá' : 'Gợi ý nhanh',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        (widget.isReadOnly ? _selectedTags : widget.reviewTags)
                            .map((tag) {
                              final isSelected = _selectedTags.contains(tag);
                              return GestureDetector(
                                onTap: widget.isReadOnly
                                    ? null
                                    : () {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedTags.remove(tag);
                                          } else {
                                            _selectedTags.add(tag);
                                          }
                                        });
                                      },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.blobLight
                                        : const Color(
                                            0xFFF0FDF4,
                                          ).withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    tag,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isSelected
                                          ? AppColors.primary
                                          : const Color(0xFF0D9488),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              );
                            })
                            .toList(),
                  ),
                ],
                if (!widget.isReadOnly) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.public, size: 14, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Đánh giá của bạn sẽ được hiển thị công khai',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 32),
                if (!widget.isReadOnly)
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Gửi đánh giá',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
