import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/destination.dart';

part 'destination_model.g.dart';

@JsonSerializable()
class DestinationModel {
  final String id;
  final String name;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @JsonKey(name: 'placeholder_color')
  final int placeholderColor;

  const DestinationModel({
    required this.id,
    required this.name,
    this.imageUrl,
    this.placeholderColor = 0xFF4A8C5C,
  });

  factory DestinationModel.fromJson(Map<String, dynamic> json) =>
      _$DestinationModelFromJson(json);

  Map<String, dynamic> toJson() => _$DestinationModelToJson(this);

  Destination toEntity() => Destination(
        id: id,
        name: name,
        imageUrl: imageUrl,
        placeholderColor: placeholderColor,
      );
}
