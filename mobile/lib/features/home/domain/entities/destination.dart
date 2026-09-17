import 'package:freezed_annotation/freezed_annotation.dart';

part 'destination.freezed.dart';

@freezed
class Destination with _$Destination {
  const factory Destination({
    required String id,
    required String name,
    String? imageUrl,
    @Default(0xFF4A8C5C) int placeholderColor,
    @Default(0.0) double averageRating,
    @Default(0) int reviewCount,
  }) = _Destination;
}