import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import 'package:travel_advisor_mobile/core/di/injection_container.dart';
import 'package:travel_advisor_mobile/core/services/activity_service.dart';
import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/core/widgets/net_image.dart';
import 'package:travel_advisor_mobile/features/review/presentation/cubit/review_cubit.dart';
import 'package:travel_advisor_mobile/features/review/presentation/cubit/review_state.dart';
import 'package:travel_advisor_mobile/features/review/presentation/widgets/review_media_list.dart';
import 'package:travel_advisor_mobile/features/review/presentation/widgets/star_rating_input.dart';

class PlaceReviewScreen extends StatefulWidget {
  final String locationId;
  final ReviewCubit reviewCubit;

  final bool isReadOnly;

  const PlaceReviewScreen({
    super.key,
    required this.locationId,
    required this.reviewCubit,
    this.isReadOnly = false,
  });

  @override
  State<PlaceReviewScreen> createState() => _PlaceReviewScreenState();
}

class _PlaceReviewScreenState extends State<PlaceReviewScreen> {
  late double _rating;
  late TextEditingController _reviewController;
  late List<String> _mediaPaths;
  late List<String> _selectedTags;

  final List<String> _quickTags = [
    'Sạch sẽ',
    'Phù hợp gia đình',
    'Đông vui',
    'Đáng tiền',
    'Check-in đẹp',
  ];

  @override
  void initState() {
    super.initState();
    final state = widget.reviewCubit.state;
    if (state is ReviewLoaded) {
      final loc = state.itinerary.locations.firstWhere((l) => l.id == widget.locationId);
      _rating = loc.rating ?? 0.0;
      _reviewController = TextEditingController(text: loc.reviewText ?? '');
      _mediaPaths = List<String>.from(loc.mediaPaths ?? []);
      _selectedTags = List<String>.from(loc.reviewTags ?? []);
    } else {
      _rating = 0.0;
      _reviewController = TextEditingController();
      _mediaPaths = [];
      _selectedTags = [];
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  String _getRatingText(double rating) {
    if (rating >= 5) return 'Tuyệt vời';
    if (rating >= 4) return 'Rất tốt';
    if (rating >= 3) return 'Bình thường';
    if (rating >= 2) return 'Tệ';
    if (rating >= 1) return 'Rất tệ';
    return '';
  }

  Future<void> _pickMedia() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _mediaPaths.addAll(pickedFiles.map((f) => f.path));
      });
    }
  }

  void _submit() {
    // Lấy placeId thực sự của POI trước khi cập nhật state
    String? placeId;
    final cubitState = widget.reviewCubit.state;
    if (cubitState is ReviewLoaded) {
      final idx = cubitState.itinerary.locations
          .indexWhere((l) => l.id == widget.locationId);
      if (idx != -1) placeId = cubitState.itinerary.locations[idx].placeId;
    }

    widget.reviewCubit.updateLocationReviewDetails(
      locationId: widget.locationId,
      rating: _rating,
      reviewText: _reviewController.text,
      reviewTags: _selectedTags,
      mediaPaths: _mediaPaths,
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

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReviewCubit, ReviewState>(
      bloc: widget.reviewCubit,
      builder: (context, state) {
        if (state is! ReviewLoaded) return const Scaffold();

        final location = state.itinerary.locations.firstWhere((l) => l.id == widget.locationId);

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Viết đánh giá',
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
                  onPressed: _submit,
                  child: Text(
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
                            const Row(
                              children: [
                                Icon(Icons.location_on, size: 12, color: AppColors.textSecondary),
                                SizedBox(width: 4),
                                Text(
                                  'TP. HCM',
                                  style: TextStyle(
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
                    onRatingChanged: widget.isReadOnly ? (_) {} : (val) {
                      setState(() => _rating = val);
                    },
                    size: 32,
                    mainAxisAlignment: MainAxisAlignment.center,
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
                  mediaPaths: _mediaPaths,
                  onAddMedia: widget.isReadOnly ? () {} : _pickMedia,
                  onRemoveMedia: widget.isReadOnly ? (_) {} : (path) {
                    setState(() => _mediaPaths.remove(path));
                  },
                  onClearAllMedia: widget.isReadOnly ? () {} : () {
                    setState(() => _mediaPaths.clear());
                  },
                  imageSize: 80,
                ),
                const SizedBox(height: 24),
                Text(
                  'Gợi ý nhanh',
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
                  children: _quickTags.map((tag) {
                    final isSelected = _selectedTags.contains(tag);
                    return GestureDetector(
                      onTap: widget.isReadOnly ? () {} : () {
                        setState(() {
                          if (isSelected) {
                            _selectedTags.remove(tag);
                          } else {
                            _selectedTags.add(tag);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.blobLight : const Color(0xFFF0FDF4).withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? AppColors.primary : const Color(0xFF0D9488),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Icon(Icons.public, size: 14, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Đánh giá của bạn sẽ được hiển thị công khai',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                if (!widget.isReadOnly)
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
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