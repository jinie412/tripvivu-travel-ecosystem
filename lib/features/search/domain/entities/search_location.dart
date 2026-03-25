import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_location.freezed.dart';

@freezed
class SearchLocation with _$SearchLocation {
  const factory SearchLocation({
    required String id,
    required String name,
    required String imageUrl,
    @Default('city') String type, // 'city' or 'place'
  }) = _SearchLocation;
}
