class TripSuggestion {
  final String id;
  final String title;
  final String authorName;
  final String authorAvatar;
  final String days;
  final String location;
  final String views;
  final String likes;
  final String? imageUrl;
  final List<String> imageUrls;
  final int placeholderColor;
  final bool isFavorite;

  const TripSuggestion({
    required this.id,
    required this.title,
    this.authorName = 'Traveler',
    this.authorAvatar = '',
    required this.days,
    required this.location,
    required this.views,
    required this.likes,
    this.imageUrl,
    this.imageUrls = const <String>[],
    this.placeholderColor = 0xFF4A90D9,
    this.isFavorite = false,
  });

  TripSuggestion copyWith({
    String? id,
    String? title,
    String? authorName,
    String? authorAvatar,
    String? days,
    String? location,
    String? views,
    String? likes,
    String? imageUrl,
    List<String>? imageUrls,
    int? placeholderColor,
    bool? isFavorite,
  }) {
    return TripSuggestion(
      id: id ?? this.id,
      title: title ?? this.title,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      days: days ?? this.days,
      location: location ?? this.location,
      views: views ?? this.views,
      likes: likes ?? this.likes,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      placeholderColor: placeholderColor ?? this.placeholderColor,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
