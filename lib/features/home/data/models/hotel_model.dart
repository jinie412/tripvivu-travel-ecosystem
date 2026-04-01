import 'package:json_annotation/json_annotation.dart';

import 'package:travel_advisor_mobile/features/home/domain/entities/hotel.dart';

part 'hotel_model.g.dart';

@JsonSerializable()
class HotelModel {
  final String id;
  final String name;
  final double rating;
  final String price;
  @JsonKey(name: 'price_unit')
  final String priceUnit;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @JsonKey(name: 'placeholder_color')
  final int placeholderColor;

  const HotelModel({
    required this.id,
    required this.name,
    required this.rating,
    required this.price,
    this.priceUnit = '1 đêm',
    this.imageUrl,
    this.placeholderColor = 0xFFD4C5B0,
  });

  factory HotelModel.fromJson(Map<String, dynamic> json) =>
      _$HotelModelFromJson(json);

  Map<String, dynamic> toJson() => _$HotelModelToJson(this);

  Hotel toEntity() => Hotel(
        id: id,
        name: name,
        rating: rating,
        price: price,
        priceUnit: priceUnit,
        imageUrl: imageUrl,
        placeholderColor: placeholderColor,
      );
}