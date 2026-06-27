import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'review_state.dart';

import 'package:travel_advisor_mobile/features/review/domain/entities/itinerary_review_entity.dart';
import 'package:travel_advisor_mobile/features/review/domain/entities/location_review_entity.dart';
import 'package:travel_advisor_mobile/features/review/domain/entities/review_media_item.dart';
import 'package:travel_advisor_mobile/features/review/domain/entities/review_types.dart';
import 'package:travel_advisor_mobile/features/review/domain/repositories/review_repository.dart';
import 'package:travel_advisor_mobile/features/review/domain/usecases/get_itinerary_for_review_usecase.dart';
import 'package:travel_advisor_mobile/features/review/presentation/utils/review_media_picker.dart';

class ReviewCubit extends Cubit<ReviewState> {
  final GetItineraryForReviewUseCase getItineraryForReview;
  final ReviewRepository reviewRepository;

  ReviewCubit({
    required this.getItineraryForReview,
    required this.reviewRepository,
  }) : super(ReviewInitial());

  static const int _maxImageSizeBytes = 2 * 1024 * 1024;
  static const int _maxVideoSizeBytes = 20 * 1024 * 1024;
  static const Duration _maxVideoDuration = Duration(seconds: 20);

  Future<void> loadReviewData(
    String itineraryId, {
    double initialRating = 0.0,
    String initialComment = '',
    bool forceRefresh = false,
  }) async {
    emit(ReviewLoading());

    try {
      final itinerary = await getItineraryForReview(
        itineraryId,
        forceRefresh: forceRefresh,
      );
      var loadedItinerary = itinerary;
      var locationRatingsBeforeApplyAll = const <String, double?>{};
      if (initialRating > 0) {
        locationRatingsBeforeApplyAll = _snapshotLocationRatings(
          loadedItinerary.locations,
        );
        loadedItinerary = _applyRatingToAllLocations(
          loadedItinerary,
          initialRating,
        );
      }

      // Nếu có địa điểm đã review, pre-fetch submitted review để:
      // 1. Hiển thị media thumbnail ngay trong tile không cần tap thêm
      // 2. Cache để mở detail view không tốn thêm 1 API call
      SubmittedReviewData? submittedReview;
      var locationMedia = const <String, List<ReviewMediaItem>>{};

      if (itinerary.locations.any((loc) => loc.hasReview)) {
        try {
          submittedReview = await reviewRepository.getSubmittedReview(
            itineraryId,
            forceRefresh: forceRefresh,
          );
          final mediaMap = <String, List<ReviewMediaItem>>{};
          for (final place in submittedReview.places) {
            if (place.mediaUrls.isNotEmpty) {
              mediaMap[place.itineraryDetailId] = place.mediaUrls
                  .asMap()
                  .entries
                  .map(
                    (e) => ReviewMediaItem.fromRemoteUrl(
                      remoteUrl: e.value,
                      sortOrder: e.key,
                    ),
                  )
                  .toList();
            }
          }
          locationMedia = mediaMap;
        } catch (_) {
          // Non-fatal: vẫn hiển thị trang bình thường,
          // chỉ mất media preview và tap detail sẽ gọi API lại
        }
      }

      emit(
        ReviewLoaded(
          itinerary: loadedItinerary,
          generalRating: initialRating,
          generalComment: initialComment,
          locationRatingsBeforeApplyAll: locationRatingsBeforeApplyAll,
          submittedReview: submittedReview,
          locationMediaByDetailId: locationMedia,
        ),
      );
    } catch (e) {
      emit(ReviewError(e.toString()));
    }
  }

  Future<void> loadSubmittedReview(String itineraryId) async {
    emit(ReviewLoading());

    try {
      final data = await reviewRepository.getSubmittedReview(itineraryId);

      final locations = data.places
          .where((p) => p.itineraryDetailId.isNotEmpty)
          .map((p) {
            return LocationReviewEntity(
              id: p.itineraryDetailId,
              name: p.placeName,
              imageUrl: p.placeImageUrl ?? '',
              day: _parseDayNumber(p.dayLabel),
              isVisited: true,
              rating: p.rating,
              reviewText: p.content,
              reviewTags: p.tags,
            );
          })
          .toList();

      final itinerary = ItineraryReviewEntity(
        id: data.itineraryId,
        title: data.itineraryTitle,
        imageUrl: data.coverImage ?? '',
        dateRange: _formatDateRange(data.startDate, data.endDate),
        status: 'COMPLETED',
        locations: locations,
      );

      final itineraryMedia = data.overallMediaUrls
          .asMap()
          .entries
          .map(
            (e) => ReviewMediaItem.fromRemoteUrl(
              remoteUrl: e.value,
              sortOrder: e.key,
            ),
          )
          .toList();

      final locationMedia = <String, List<ReviewMediaItem>>{};
      for (final place in data.places) {
        if (place.mediaUrls.isNotEmpty) {
          locationMedia[place.itineraryDetailId] = place.mediaUrls
              .asMap()
              .entries
              .map(
                (e) => ReviewMediaItem.fromRemoteUrl(
                  remoteUrl: e.value,
                  sortOrder: e.key,
                ),
              )
              .toList();
        }
      }

      emit(
        ReviewLoaded(
          itinerary: itinerary,
          generalRating: data.overallRating ?? 0.0,
          generalComment: data.overallContent ?? '',
          generalTags: data.overallTags,
          itineraryMedia: itineraryMedia,
          locationMediaByDetailId: locationMedia,
          submittedReview: data,
        ),
      );
    } catch (e) {
      emit(ReviewError(e.toString()));
    }
  }

  int _parseDayNumber(String label) {
    final match = RegExp(r'(\d+)').firstMatch(label.toUpperCase());
    return int.tryParse(match?.group(1) ?? '') ?? 1;
  }

  String _formatDateRange(String startDate, String endDate) {
    if (startDate.isEmpty && endDate.isEmpty) return '';
    String fmt(String iso) {
      try {
        final dt = DateTime.parse(iso);
        return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      } catch (_) {
        return iso;
      }
    }

    if (startDate.isEmpty) return fmt(endDate);
    if (endDate.isEmpty) return fmt(startDate);
    return '${fmt(startDate)} - ${fmt(endDate)}';
  }

  void filterByDay(int day) {
    if (state is ReviewLoaded) {
      emit((state as ReviewLoaded).copyWith(selectedDay: day));
    }
  }

  Map<String, double?> _snapshotLocationRatings(
    List<LocationReviewEntity> locations,
  ) {
    return {
      for (final loc in locations)
        if (!loc.hasReview) loc.id: loc.rating,
    };
  }

  ItineraryReviewEntity _applyRatingToAllLocations(
    ItineraryReviewEntity itinerary,
    double rating,
  ) {
    final appliedRating = rating > 0 ? rating : null;
    final newLocations = itinerary.locations
        .map((loc) {
          if (loc.hasReview) {
            return loc;
          }
          if (loc.rating == appliedRating) {
            return loc;
          }
          return loc.copyWith(rating: appliedRating);
        })
        .toList(growable: false);

    return itinerary.copyWith(locations: newLocations);
  }

  ItineraryReviewEntity _restoreLocationRatings(
    ItineraryReviewEntity itinerary,
    Map<String, double?> ratingsByLocationId,
  ) {
    if (ratingsByLocationId.isEmpty) {
      return itinerary;
    }

    final newLocations = itinerary.locations
        .map((loc) {
          if (loc.hasReview) {
            return loc;
          }
          if (!ratingsByLocationId.containsKey(loc.id)) {
            return loc;
          }

          final restoredRating = ratingsByLocationId[loc.id];
          if (loc.rating == restoredRating) {
            return loc;
          }

          return loc.copyWith(rating: restoredRating);
        })
        .toList(growable: false);

    return itinerary.copyWith(locations: newLocations);
  }

  void setGeneralRating(double rating) {
    if (state is ReviewLoaded) {
      final currentState = state as ReviewLoaded;
      var newItinerary = currentState.itinerary;
      var ratingsBeforeApplyAll = currentState.locationRatingsBeforeApplyAll;

      if (currentState.applyToAllLocations) {
        if (ratingsBeforeApplyAll.isEmpty) {
          ratingsBeforeApplyAll = _snapshotLocationRatings(
            newItinerary.locations,
          );
        }
        newItinerary = _applyRatingToAllLocations(newItinerary, rating);
      }

      emit(
        currentState.copyWith(
          generalRating: rating,
          itinerary: newItinerary,
          locationRatingsBeforeApplyAll: ratingsBeforeApplyAll,
        ),
      );
    }
  }

  void setGeneralComment(String comment) {
    if (state is ReviewLoaded) {
      emit((state as ReviewLoaded).copyWith(generalComment: comment));
    }
  }

  void toggleGeneralTag(String tag) {
    if (state is ReviewLoaded) {
      final currentState = state as ReviewLoaded;
      final tags = List<String>.from(currentState.generalTags);
      if (tags.contains(tag)) {
        tags.remove(tag);
      } else {
        tags.add(tag);
      }
      emit(currentState.copyWith(generalTags: List<String>.unmodifiable(tags)));
    }
  }

  void toggleApplyToAll(bool value) {
    if (state is ReviewLoaded) {
      final currentState = state as ReviewLoaded;

      var newItinerary = currentState.itinerary;
      var ratingsBeforeApplyAll = currentState.locationRatingsBeforeApplyAll;
      if (value) {
        ratingsBeforeApplyAll = _snapshotLocationRatings(
          newItinerary.locations,
        );
        newItinerary = _applyRatingToAllLocations(
          newItinerary,
          currentState.generalRating,
        );
      } else {
        newItinerary = _restoreLocationRatings(
          newItinerary,
          ratingsBeforeApplyAll,
        );
        ratingsBeforeApplyAll = const {};
      }

      emit(
        currentState.copyWith(
          applyToAllLocations: value,
          itinerary: newItinerary,
          locationRatingsBeforeApplyAll: ratingsBeforeApplyAll,
        ),
      );
    }
  }

  void setLocationRating(String locationId, double rating) {
    if (state is ReviewLoaded) {
      final currentState = state as ReviewLoaded;
      if (currentState.itinerary.locations.any(
        (loc) => loc.id == locationId && loc.hasReview,
      )) {
        return;
      }

      final newLocations = currentState.itinerary.locations.map((loc) {
        if (loc.id == locationId) {
          return loc.copyWith(rating: rating);
        }
        return loc;
      }).toList();

      final newItinerary = currentState.itinerary.copyWith(
        locations: newLocations,
      );

      emit(
        currentState.copyWith(
          itinerary: newItinerary,
          applyToAllLocations: false,
          locationRatingsBeforeApplyAll: const {},
        ),
      );
    }
  }

  void updateLocationReviewDetails({
    required String locationId,
    double? rating,
    String? reviewText,
    List<String>? reviewTags,
    List<ReviewMediaItem>? mediaItems,
  }) {
    if (state is ReviewLoaded) {
      final currentState = state as ReviewLoaded;
      if (currentState.itinerary.locations.any(
        (loc) => loc.id == locationId && loc.hasReview,
      )) {
        return;
      }

      final newLocations = currentState.itinerary.locations.map((loc) {
        if (loc.id == locationId) {
          return loc.copyWith(
            rating: rating ?? loc.rating,
            reviewText: reviewText ?? loc.reviewText,
            reviewTags: reviewTags ?? loc.reviewTags,
          );
        }
        return loc;
      }).toList();

      final newItinerary = currentState.itinerary.copyWith(
        locations: newLocations,
      );
      final newLocationMedia = Map<String, List<ReviewMediaItem>>.from(
        currentState.locationMediaByDetailId,
      );
      if (mediaItems != null) {
        newLocationMedia[locationId] = List<ReviewMediaItem>.unmodifiable(
          mediaItems,
        );
      }

      emit(
        currentState.copyWith(
          itinerary: newItinerary,
          applyToAllLocations: false,
          locationRatingsBeforeApplyAll: const {},
          locationMediaByDetailId: newLocationMedia,
        ),
      );
    }
  }

  void ensureLocationAvailable(LocationReviewEntity location) {
    if (state is! ReviewLoaded) return;

    final currentState = state as ReviewLoaded;
    final exists = currentState.itinerary.locations.any(
      (loc) => loc.id == location.id,
    );
    if (exists) return;

    final newItinerary = currentState.itinerary.copyWith(
      locations: [...currentState.itinerary.locations, location],
    );
    emit(currentState.copyWith(itinerary: newItinerary));
  }

  Future<void> addImages() async {
    if (state is ReviewLoaded) {
      final currentState = state as ReviewLoaded;
      final pickedMedia = await ReviewMediaPicker.pickImages(
        startSortOrder: currentState.itineraryMedia.length,
      );

      if (pickedMedia.isNotEmpty) {
        final newMedia = List<ReviewMediaItem>.from(currentState.itineraryMedia)
          ..addAll(pickedMedia);
        emit(currentState.copyWith(itineraryMedia: newMedia));
      }
    }
  }

  Future<void> addVideo() async {
    if (state is ReviewLoaded) {
      final currentState = state as ReviewLoaded;
      String? preparingVideoId;
      void removePreparingVideo() {
        if (preparingVideoId == null || state is! ReviewLoaded) {
          return;
        }
        final latestState = state as ReviewLoaded;
        final newMedia = List<ReviewMediaItem>.from(latestState.itineraryMedia)
          ..removeWhere((item) => item.id == preparingVideoId);
        emit(latestState.copyWith(itineraryMedia: newMedia));
      }

      final ReviewMediaItem? video;
      try {
        video = await ReviewMediaPicker.pickVideo(
          sortOrder: currentState.itineraryMedia.length,
          onPreparingVideo: (item) {
            preparingVideoId = item.id;
            if (state is! ReviewLoaded) {
              return;
            }
            final latestState = state as ReviewLoaded;
            final newMedia = List<ReviewMediaItem>.from(
              latestState.itineraryMedia,
            );
            final existingIndex = newMedia.indexWhere(
              (mediaItem) => mediaItem.id == item.id,
            );
            if (existingIndex >= 0) {
              newMedia[existingIndex] = item;
            } else {
              newMedia.add(item);
            }
            emit(latestState.copyWith(itineraryMedia: newMedia));
          },
        );
      } catch (_) {
        removePreparingVideo();
        rethrow;
      }

      if (video != null) {
        final selectedVideo = video;
        if (state is! ReviewLoaded) {
          return;
        }
        final latestState = state as ReviewLoaded;
        final newMedia = List<ReviewMediaItem>.from(latestState.itineraryMedia);
        final existingIndex = newMedia.indexWhere(
          (item) => item.id == selectedVideo.id,
        );
        if (existingIndex >= 0) {
          newMedia[existingIndex] = selectedVideo;
        } else {
          newMedia.add(selectedVideo);
        }
        emit(latestState.copyWith(itineraryMedia: newMedia));
      } else {
        removePreparingVideo();
      }
    }
  }

  void removeMedia(String mediaId) {
    if (state is ReviewLoaded) {
      final currentState = state as ReviewLoaded;
      final newMedia = List<ReviewMediaItem>.from(currentState.itineraryMedia)
        ..removeWhere((item) => item.id == mediaId);
      emit(currentState.copyWith(itineraryMedia: newMedia));
    }
  }

  void clearAllMedia() {
    if (state is ReviewLoaded) {
      final currentState = state as ReviewLoaded;
      emit(currentState.copyWith(itineraryMedia: []));
    }
  }

  void _setSubmitting(bool isSubmitting) {
    if (state is ReviewLoaded) {
      emit((state as ReviewLoaded).copyWith(isSubmitting: isSubmitting));
    }
  }

  void _updateItineraryMediaItem(ReviewMediaItem updatedItem) {
    if (state is! ReviewLoaded) {
      return;
    }

    final currentState = state as ReviewLoaded;
    final media = currentState.itineraryMedia
        .map((item) => item.id == updatedItem.id ? updatedItem : item)
        .toList(growable: false);
    emit(currentState.copyWith(itineraryMedia: media));
  }

  void _updateLocationMediaItem(
    String locationId,
    ReviewMediaItem updatedItem,
  ) {
    if (state is! ReviewLoaded) {
      return;
    }

    final currentState = state as ReviewLoaded;
    final locationMedia = Map<String, List<ReviewMediaItem>>.from(
      currentState.locationMediaByDetailId,
    );
    final media = (locationMedia[locationId] ?? const <ReviewMediaItem>[])
        .map((item) => item.id == updatedItem.id ? updatedItem : item)
        .toList(growable: false);
    locationMedia[locationId] = media;
    emit(currentState.copyWith(locationMediaByDetailId: locationMedia));
  }

  String _fileNameFromPath(String path) {
    return path.split(RegExp(r'[\\/]')).last;
  }

  int _maxSizeForMedia(ReviewMediaType type) {
    return switch (type) {
      ReviewMediaType.image => _maxImageSizeBytes,
      ReviewMediaType.video => _maxVideoSizeBytes,
    };
  }

  Future<List<SubmitReviewMediaInput>> _uploadMediaScope({
    required String scope,
    required String itineraryId,
    String? itineraryDetailId,
    required List<ReviewMediaItem> mediaItems,
    required void Function(ReviewMediaItem item) onItemChanged,
  }) async {
    if (mediaItems.isEmpty) {
      return const [];
    }

    final candidates = <ReviewMediaUploadCandidate>[];
    final hydratedItems = <ReviewMediaItem>[];

    for (final item in mediaItems) {
      final file = File(item.localPath);
      final exists = await file.exists();
      if (!exists) {
        final failed = item.copyWith(
          status: ReviewMediaUploadStatus.failed,
          errorMessage: 'Không tìm thấy tệp đã chọn',
        );
        onItemChanged(failed);
        throw Exception('Không tìm thấy tệp media: ${item.localPath}');
      }

      final size = await file.length();
      final maxSize = _maxSizeForMedia(item.type);
      if (size <= 0 || size > maxSize) {
        final failed = item.copyWith(
          status: ReviewMediaUploadStatus.failed,
          fileSize: size,
          errorMessage: 'Tệp vượt quá dung lượng cho phép',
        );
        onItemChanged(failed);
        throw Exception('Tệp media vượt quá dung lượng cho phép');
      }

      if (item.type == ReviewMediaType.video) {
        final duration = item.duration;
        if (duration == null || duration > _maxVideoDuration) {
          final failed = item.copyWith(
            status: ReviewMediaUploadStatus.failed,
            fileSize: size,
            errorMessage: 'Video phải ngắn hơn hoặc bằng 20 giây',
          );
          onItemChanged(failed);
          throw Exception('Video vượt quá thời lượng cho phép');
        }
      }

      final contentType =
          item.contentType ??
          (item.type == ReviewMediaType.video ? 'video/mp4' : 'image/jpeg');
      final hydrated = item.copyWith(
        status: ReviewMediaUploadStatus.requestingUrl,
        contentType: contentType,
        fileSize: size,
        errorMessage: '',
      );
      hydratedItems.add(hydrated);
      onItemChanged(hydrated);
      candidates.add(
        ReviewMediaUploadCandidate(
          fileName: _fileNameFromPath(item.localPath),
          contentType: contentType,
          size: size,
          sortOrder: item.sortOrder,
        ),
      );
    }

    final presignedUrls = await reviewRepository.createReviewPresignedUrls(
      scope: scope,
      itineraryId: itineraryId,
      itineraryDetailId: itineraryDetailId,
      files: candidates,
    );

    if (presignedUrls.length != hydratedItems.length) {
      for (final item in hydratedItems) {
        onItemChanged(
          item.copyWith(
            status: ReviewMediaUploadStatus.failed,
            errorMessage: 'Không nhận đủ upload URL',
          ),
        );
      }
      throw Exception('Không nhận đủ presigned URL cho media');
    }

    final submitMedia = <SubmitReviewMediaInput>[];

    await Future.wait(
      hydratedItems.asMap().entries.map((entry) async {
        final index = entry.key;
        final item = entry.value;
        final presignedUrl = presignedUrls[index];
        final uploading = item.copyWith(
          status: ReviewMediaUploadStatus.uploading,
          objectKey: presignedUrl.objectKey,
          remoteUrl: presignedUrl.publicUrl,
          uploadProgress: 0,
        );
        onItemChanged(uploading);

        try {
          var lastProgressPercent = 0;
          await reviewRepository.uploadReviewMediaToR2(
            presignedUrl: presignedUrl,
            localPath: item.localPath,
            contentType:
                item.contentType ??
                (item.type == ReviewMediaType.video
                    ? 'video/mp4'
                    : 'image/jpeg'),
            contentLength: item.fileSize ?? 0,
            onSendProgress: (sent, total) {
              final denominator = total > 0 ? total : item.fileSize ?? 0;
              if (denominator <= 0) {
                return;
              }
              final progress = (sent / denominator).clamp(0.0, 1.0).toDouble();
              final progressPercent = (progress * 100).floor();
              if (progressPercent < 100 &&
                  progressPercent - lastProgressPercent < 5) {
                return;
              }
              lastProgressPercent = progressPercent;
              onItemChanged(uploading.copyWith(uploadProgress: progress));
            },
          );

          final uploaded = uploading.copyWith(
            status: ReviewMediaUploadStatus.uploaded,
            uploadProgress: 1,
            errorMessage: '',
          );
          onItemChanged(uploaded);
          submitMedia.add(
            SubmitReviewMediaInput(
              objectKey: presignedUrl.objectKey,
              mediaType: presignedUrl.mediaType,
              sortOrder: presignedUrl.sortOrder,
            ),
          );
        } catch (error) {
          onItemChanged(
            uploading.copyWith(
              status: ReviewMediaUploadStatus.failed,
              errorMessage: 'Tải media thất bại',
            ),
          );
          rethrow;
        }
      }),
    );

    submitMedia.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return submitMedia;
  }

  /// Submits a review for a single place (from itinerary detail screen).
  /// Uses the /reviews endpoint — never creates an itinerary_reviews row.
  Future<void> submitSinglePlaceReview({
    required String itineraryId,
    required String locationId,
  }) async {
    if (state is! ReviewLoaded) {
      throw StateError('Du lieu danh gia chua san sang.');
    }
    final currentState = state as ReviewLoaded;

    final locIdx = currentState.itinerary.locations.indexWhere(
      (l) => l.id == locationId,
    );
    if (locIdx == -1) {
      throw StateError('Khong tim thay dia diem can danh gia.');
    }

    final loc = currentState.itinerary.locations[locIdx];
    if (loc.rating == null) {
      throw StateError('Vui long chon so sao truoc khi gui.');
    }
    if (loc.placeId == null || loc.placeId!.isEmpty) {
      throw StateError('Khong tim thay ma dia diem de luu danh gia.');
    }

    emit(currentState.copyWith(isSubmitting: true));

    try {
      final locationMedia =
          currentState.locationMediaByDetailId[locationId] ??
          const <ReviewMediaItem>[];

      await _uploadMediaScope(
        scope: 'place',
        itineraryId: itineraryId,
        itineraryDetailId: locationId,
        mediaItems: locationMedia,
        onItemChanged: (item) => _updateLocationMediaItem(locationId, item),
      );

      // Collect public URLs from updated state after upload
      final afterUpload = state is ReviewLoaded ? state as ReviewLoaded : null;
      final uploadedItems =
          afterUpload?.locationMediaByDetailId[locationId] ??
          const <ReviewMediaItem>[];
      final imageUrls = uploadedItems
          .where(
            (item) =>
                item.status == ReviewMediaUploadStatus.uploaded &&
                (item.remoteUrl?.isNotEmpty ?? false),
          )
          .map((item) => item.remoteUrl!)
          .toList();

      final contentText = loc.reviewText?.trim();

      await reviewRepository.submitPlaceReview(
        placeId: loc.placeId!,
        itineraryId: itineraryId,
        rating: loc.rating!,
        content: (contentText?.isNotEmpty ?? false) ? contentText : null,
        tags: loc.reviewTags ?? const [],
        images: imageUrls,
      );

      // Mark location as reviewed in state — no re-fetch needed
      final afterSubmit = state is ReviewLoaded ? state as ReviewLoaded : null;
      if (afterSubmit != null) {
        final updatedLocations = afterSubmit.itinerary.locations
            .map((l) => l.id == locationId ? l.copyWith(hasReview: true) : l)
            .toList(growable: false);
        emit(
          afterSubmit.copyWith(
            isSubmitting: false,
            itinerary: afterSubmit.itinerary.copyWith(
              locations: updatedLocations,
            ),
          ),
        );
      } else {
        _setSubmitting(false);
      }
    } catch (_) {
      _setSubmitting(false);
      rethrow;
    }
  }

  Future<void> submitReview(String itineraryId) async {
    if (state is! ReviewLoaded) {
      return;
    }

    final currentState = state as ReviewLoaded;
    emit(currentState.copyWith(isSubmitting: true));

    try {
      // Fail fast: validate before any IO
      for (final loc in currentState.itinerary.locations) {
        if (loc.hasReview) {
          continue;
        }
        final locationMedia =
            currentState.locationMediaByDetailId[loc.id] ??
            const <ReviewMediaItem>[];
        if (locationMedia.isNotEmpty && loc.rating == null) {
          for (final item in locationMedia) {
            _updateLocationMediaItem(
              loc.id,
              item.copyWith(
                status: ReviewMediaUploadStatus.failed,
                errorMessage: 'Vui lòng chọn số sao trước khi gửi ảnh',
              ),
            );
          }
          throw Exception('Vui lòng chọn số sao cho địa điểm có media');
        }
      }

      // Start itinerary media upload
      final itineraryMediaFuture = _uploadMediaScope(
        scope: 'itinerary',
        itineraryId: itineraryId,
        mediaItems: currentState.itineraryMedia,
        onItemChanged: _updateItineraryMediaItem,
      );

      // Start all location uploads concurrently (skip locations with no rating)
      final locationsToReview = currentState.itinerary.locations
          .where((loc) => !loc.hasReview && loc.rating != null)
          .toList();

      final locationUploadsFuture = Future.wait(
        locationsToReview.map((loc) async {
          final locationMedia =
              currentState.locationMediaByDetailId[loc.id] ??
              const <ReviewMediaItem>[];
          final uploadedMedia = await _uploadMediaScope(
            scope: 'place',
            itineraryId: itineraryId,
            itineraryDetailId: loc.id,
            mediaItems: locationMedia,
            onItemChanged: (item) => _updateLocationMediaItem(loc.id, item),
          );
          return SubmitPlaceReviewInput(
            itineraryDetailId: loc.id,
            rating: loc.rating!.round(),
            content: loc.reviewText,
            tags: loc.reviewTags ?? const [],
            media: uploadedMedia,
          );
        }),
      );

      // Both futures run concurrently; collect results
      final itineraryMedia = await itineraryMediaFuture;
      final placeReviews = await locationUploadsFuture;

      await reviewRepository.submitItineraryReview(
        itineraryId: itineraryId,
        overallRating: currentState.generalRating > 0
            ? currentState.generalRating
            : null,
        overallContent: currentState.generalComment,
        overallTags: currentState.generalTags,
        applyAllPlaces: currentState.applyToAllLocations,
        placeReviews: placeReviews,
        media: itineraryMedia,
      );

      // Mark submitted locations as reviewed locally — no re-fetch needed
      final afterSubmit = state is ReviewLoaded ? state as ReviewLoaded : null;
      if (afterSubmit != null && locationsToReview.isNotEmpty) {
        final submittedIds = {for (final loc in locationsToReview) loc.id};
        final updatedLocations = afterSubmit.itinerary.locations
            .map(
              (loc) => submittedIds.contains(loc.id)
                  ? loc.copyWith(hasReview: true)
                  : loc,
            )
            .toList(growable: false);
        emit(
          afterSubmit.copyWith(
            isSubmitting: false,
            itinerary: afterSubmit.itinerary.copyWith(
              locations: updatedLocations,
            ),
          ),
        );
      } else {
        _setSubmitting(false);
      }
    } catch (_) {
      _setSubmitting(false);
      rethrow;
    }
  }
}
