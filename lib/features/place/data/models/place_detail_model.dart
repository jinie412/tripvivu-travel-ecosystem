import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/place_detail_entity.dart';
import 'place_model.dart';
import 'place_review_model.dart';

part 'place_detail_model.g.dart';

@JsonSerializable()
class PlaceDetailModel {
  final String id;
  final String name;
  final String address;
  final String district;
  final String city;
  final double rating;
  @JsonKey(name: 'total_reviews')
  final int totalReviews;
  final List<String> tags;
  final List<String> images;
  final String description;
  @JsonKey(name: 'opening_hours')
  final String openingHours;
  @JsonKey(name: 'closing_hours')
  final String closingHours;
  final String phone;
  final List<PlaceReviewModel> reviews;
  @JsonKey(name: 'related_places')
  final List<PlaceModel> relatedPlaces;
  @JsonKey(name: 'is_favorite')
  final bool isFavorite;

  const PlaceDetailModel({
    required this.id,
    required this.name,
    required this.address,
    required this.district,
    required this.city,
    required this.rating,
    required this.totalReviews,
    this.tags = const [],
    this.images = const [],
    required this.description,
    required this.openingHours,
    required this.closingHours,
    required this.phone,
    this.reviews = const [],
    this.relatedPlaces = const [],
    this.isFavorite = false,
  });

  factory PlaceDetailModel.fromJson(Map<String, dynamic> json) => _$PlaceDetailModelFromJson(json);
  Map<String, dynamic> toJson() => _$PlaceDetailModelToJson(this);

  PlaceDetailEntity toEntity() => PlaceDetailEntity(
    id: id,
    name: name,
    address: address,
    district: district,
    city: city,
    rating: rating,
    totalReviews: totalReviews,
    tags: tags,
    images: images,
    description: description,
    openingHours: openingHours,
    closingHours: closingHours,
    phone: phone,
    reviews: reviews.map((e) => e.toEntity()).toList(),
    relatedPlaces: relatedPlaces.map((e) => e.toEntity()).toList(),
    isFavorite: isFavorite,
  );
}
