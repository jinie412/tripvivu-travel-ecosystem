import 'package:equatable/equatable.dart';

class FoodItemEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final int quantity;

  const FoodItemEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.category = 'main',
    this.quantity = 0,
  });

  FoodItemEntity copyWith({int? quantity}) {
    return FoodItemEntity(
      id: id,
      title: title,
      description: description,
      price: price,
      imageUrl: imageUrl,
      category: category,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  List<Object?> get props => [id, title, description, price, imageUrl, category, quantity];
}