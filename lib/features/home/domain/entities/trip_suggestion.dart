import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip_suggestion.freezed.dart';

@freezed
class TripSuggestion with _$TripSuggestion {
  const factory TripSuggestion({
    required String id,
    required String title,
    required String days,
    required String location,
    required String views,
    required String likes,
    String? imageUrl,
    @Default(0xFF4A90D9) int placeholderColor,
  }) = _TripSuggestion;
}
