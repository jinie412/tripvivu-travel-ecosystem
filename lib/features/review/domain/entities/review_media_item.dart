enum ReviewMediaType { image, video }

enum ReviewMediaUploadStatus {
  local,
  compressing,
  requestingUrl,
  uploading,
  uploaded,
  failed,
}

class ReviewMediaItem {
  final String id;
  final String localPath;
  final ReviewMediaType type;
  final ReviewMediaUploadStatus status;
  final String? remoteUrl;
  final String? objectKey;
  final String? contentType;
  final int? fileSize;
  final Duration? duration;
  final int sortOrder;
  final double? uploadProgress;
  final String? errorMessage;

  const ReviewMediaItem({
    required this.id,
    required this.localPath,
    required this.type,
    required this.status,
    required this.sortOrder,
    this.remoteUrl,
    this.objectKey,
    this.contentType,
    this.fileSize,
    this.duration,
    this.uploadProgress,
    this.errorMessage,
  });

  factory ReviewMediaItem.localImage({
    required String localPath,
    required int sortOrder,
  }) {
    return ReviewMediaItem(
      id: '${DateTime.now().microsecondsSinceEpoch}-$sortOrder',
      localPath: localPath,
      type: ReviewMediaType.image,
      status: ReviewMediaUploadStatus.local,
      contentType: _guessImageContentType(localPath),
      sortOrder: sortOrder,
    );
  }

  factory ReviewMediaItem.fromRemoteUrl({
    required String remoteUrl,
    required int sortOrder,
  }) {
    final url = remoteUrl.toLowerCase();
    final isVideo = url.contains('/videos/') ||
        url.endsWith('.mp4') ||
        url.endsWith('.mov') ||
        url.endsWith('.webm');
    return ReviewMediaItem(
      id: 'remote_${sortOrder}_${remoteUrl.hashCode.abs()}',
      localPath: remoteUrl,
      type: isVideo ? ReviewMediaType.video : ReviewMediaType.image,
      status: ReviewMediaUploadStatus.uploaded,
      remoteUrl: remoteUrl,
      sortOrder: sortOrder,
    );
  }

  factory ReviewMediaItem.localVideo({
    required String localPath,
    required int sortOrder,
    required int fileSize,
    required Duration duration,
  }) {
    return ReviewMediaItem(
      id: '${DateTime.now().microsecondsSinceEpoch}-$sortOrder',
      localPath: localPath,
      type: ReviewMediaType.video,
      status: ReviewMediaUploadStatus.local,
      contentType: _guessVideoContentType(localPath),
      fileSize: fileSize,
      duration: duration,
      sortOrder: sortOrder,
    );
  }

  ReviewMediaItem copyWith({
    String? id,
    String? localPath,
    ReviewMediaType? type,
    ReviewMediaUploadStatus? status,
    String? remoteUrl,
    String? objectKey,
    String? contentType,
    int? fileSize,
    Duration? duration,
    int? sortOrder,
    double? uploadProgress,
    String? errorMessage,
  }) {
    return ReviewMediaItem(
      id: id ?? this.id,
      localPath: localPath ?? this.localPath,
      type: type ?? this.type,
      status: status ?? this.status,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      objectKey: objectKey ?? this.objectKey,
      contentType: contentType ?? this.contentType,
      fileSize: fileSize ?? this.fileSize,
      duration: duration ?? this.duration,
      sortOrder: sortOrder ?? this.sortOrder,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  String get submitMediaType {
    return switch (type) {
      ReviewMediaType.image => 'image',
      ReviewMediaType.video => 'video',
    };
  }

  static String _guessImageContentType(String path) {
    final normalized = path.toLowerCase();
    if (normalized.endsWith('.png')) {
      return 'image/png';
    }
    if (normalized.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  static String _guessVideoContentType(String path) {
    final normalized = path.toLowerCase();
    if (normalized.endsWith('.mov') || normalized.endsWith('.qt')) {
      return 'video/quicktime';
    }
    return 'video/mp4';
  }
}
