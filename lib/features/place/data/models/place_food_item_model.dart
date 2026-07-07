import 'package:json_annotation/json_annotation.dart';

import 'package:travel_advisor_mobile/features/place/domain/entities/place_food_item_entity.dart';

part 'place_food_item_model.g.dart';

@JsonSerializable()
class PlaceFoodItemModel {
  final String id;
  final String name;
  final String description;
  final double price;
  @JsonKey(name: 'image_url')
  final String imageUrl;
  final String? category;

  const PlaceFoodItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.category,
  });

  factory PlaceFoodItemModel.fromJson(Map<String, dynamic> json) =>
      _$PlaceFoodItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$PlaceFoodItemModelToJson(this);

  PlaceFoodItemEntity toEntity() => PlaceFoodItemEntity(
        id: id,
        name: name,
        description: description,
        price: price,
        imageUrl: imageUrl,
        category: category,
      );
}