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
  });
}