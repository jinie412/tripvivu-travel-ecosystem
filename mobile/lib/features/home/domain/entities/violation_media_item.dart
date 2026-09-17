enum ViolationMediaType { image, video }

class ViolationMediaItem {
  final String url;
  final ViolationMediaType mediaType;
  final List<String> categories;

  const ViolationMediaItem({
    required this.url,
    required this.mediaType,
    this.categories = const [],
  });
}
