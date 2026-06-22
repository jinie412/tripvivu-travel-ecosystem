import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:travel_advisor_mobile/features/review/domain/entities/review_media_item.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';

class ReviewMediaPicker {
  static const int maxVideoSizeBytes = 20 * 1024 * 1024;
  static const int compressionThresholdBytes = 5 * 1024 * 1024;
  static const Duration maxVideoDuration = Duration(seconds: 20);

  static Future<List<ReviewMediaItem>> pickImages({
    required int startSortOrder,
  }) async {
    final pickedFiles = await ImagePicker().pickMultiImage();
    if (pickedFiles.isEmpty) {
      return const [];
    }

    return pickedFiles
        .asMap()
        .entries
        .map((entry) {
          return ReviewMediaItem.localImage(
            localPath: entry.value.path,
            sortOrder: startSortOrder + entry.key,
          );
        })
        .toList(growable: false);
  }

  static Future<ReviewMediaItem?> pickVideo({
    required int sortOrder,
    void Function(ReviewMediaItem item)? onPreparingVideo,
  }) async {
    final pickedFile = await ImagePicker().pickVideo(
      source: ImageSource.gallery,
      maxDuration: maxVideoDuration,
    );

    if (pickedFile == null) {
      return null;
    }

    final file = File(pickedFile.path);
    final size = await file.length();
    if (size <= 0) {
      throw const ReviewMediaSelectionException('Video không hợp lệ');
    }

    final duration = await _readVideoDuration(file);
    if (duration > maxVideoDuration) {
      throw const ReviewMediaSelectionException(
        'Video phải ngắn hơn hoặc bằng 20 giây',
      );
    }

    final selectedVideo = ReviewMediaItem.localVideo(
      localPath: pickedFile.path,
      sortOrder: sortOrder,
      fileSize: size,
      duration: duration,
    );

    void notifyCompressProgress(double progress) {
      onPreparingVideo?.call(
        selectedVideo.copyWith(
          status: ReviewMediaUploadStatus.compressing,
          uploadProgress: progress.clamp(0.0, 1.0).toDouble(),
          errorMessage: 'Đang nén video',
        ),
      );
    }

    if (size <= compressionThresholdBytes) {
      return selectedVideo;
    }

    notifyCompressProgress(0);

    final preparedVideo = await _compressVideoIfNeeded(
      file,
      onCompressProgress: notifyCompressProgress,
    );

    return selectedVideo.copyWith(
      localPath: preparedVideo.path,
      status: ReviewMediaUploadStatus.local,
      contentType: 'video/mp4',
      fileSize: preparedVideo.size,
      errorMessage: '',
    );
  }

  static Future<_PreparedVideo> _compressVideoIfNeeded(
    File file, {
    void Function(double progress)? onCompressProgress,
  }) async {
    MediaInfo? bestCompressed;
    int? bestSize;
    Subscription? subscription;
    var lastProgressPercent = 0;

    try {
      if (onCompressProgress != null) {
        subscription = VideoCompress.compressProgress$.subscribe((progress) {
          final normalized = (progress / 100).clamp(0.0, 1.0).toDouble();
          final progressPercent = (normalized * 100).floor();
          if (progressPercent < 100 &&
              progressPercent - lastProgressPercent < 3) {
            return;
          }
          lastProgressPercent = progressPercent;
          onCompressProgress(normalized);
        });
      }

      for (final quality in const [
        VideoQuality.MediumQuality,
        VideoQuality.LowQuality,
      ]) {
        final mediaInfo = await VideoCompress.compressVideo(
          file.path,
          quality: quality,
          deleteOrigin: false,
          includeAudio: true,
        );

        final compressedPath = mediaInfo?.path;
        if (compressedPath == null || compressedPath.isEmpty) {
          continue;
        }

        final compressedFile = File(compressedPath);
        if (!await compressedFile.exists()) {
          continue;
        }

        final compressedSize = await compressedFile.length();
        if (compressedSize <= 0) {
          continue;
        }

        if (bestSize == null || compressedSize < bestSize) {
          bestCompressed = mediaInfo;
          bestSize = compressedSize;
        }

        if (compressedSize <= maxVideoSizeBytes) {
          break;
        }
      }
    } finally {
      subscription?.unsubscribe();
    }

    final compressedPath = bestCompressed?.path;
    final compressedSize = bestSize;
    if (compressedPath == null ||
        compressedPath.isEmpty ||
        compressedSize == null) {
      throw const ReviewMediaSelectionException(
        'Không thể nén video, vui lòng chọn video khác',
      );
    }

    if (compressedSize > maxVideoSizeBytes) {
      throw const ReviewMediaSelectionException(
        'Video vẫn vượt quá 20MB sau khi nén',
      );
    }

    return _PreparedVideo(path: compressedPath, size: compressedSize);
  }

  static Future<Duration> _readVideoDuration(File file) async {
    final controller = VideoPlayerController.file(file);
    try {
      await controller.initialize();
      return controller.value.duration;
    } finally {
      await controller.dispose();
    }
  }
}

class _PreparedVideo {
  final String path;
  final int size;

  const _PreparedVideo({required this.path, required this.size});
}

class ReviewMediaSelectionException implements Exception {
  final String message;

  const ReviewMediaSelectionException(this.message);

  @override
  String toString() => message;
}
