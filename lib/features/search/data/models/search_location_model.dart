import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/search_location.dart';

part 'search_location_model.freezed.dart';
part 'search_location_model.g.dart';

@freezed
class SearchLocationModel with _$SearchLocationModel {
  const factory SearchLocationModel({
    required String id,
    required String name,
    required String imageUrl,
    @Default('city') String type,
  }) = _SearchLocationModel;

  factory SearchLocationModel.fromJson(Map<String, dynamic> json) =>
      _$SearchLocationModelFromJson(json);
}

extension SearchLocationModelX on SearchLocationModel {
  SearchLocation toEntity() {
    return SearchLocation(
      id: id,
      name: name,
      imageUrl: imageUrl,
      type: type,
    );
  }
}
