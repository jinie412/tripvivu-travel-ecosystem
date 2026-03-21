import 'package:equatable/equatable.dart';

class FoodItemEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final double price;
  final String imageUrl;
  final int quantity;

  const FoodItemEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.quantity = 0,
  });

  FoodItemEntity copyWith({int? quantity}) {
    return FoodItemEntity(
      id: id,
      title: title,
      description: description,
      price: price,
      imageUrl: imageUrl,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  List<Object?> get props => [id, title, description, price, imageUrl, quantity];
}
