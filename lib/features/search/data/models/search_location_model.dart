// lib/features/search/data/models/search_location_model.dart

import 'package:travel_advisor_mobile/features/search/domain/entities/search_location.dart';

class SearchLocationModel {
  final String id;
  final String name;
  final String imageUrl;
  final String type;

  const SearchLocationModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.type = 'city',
  });

  /// Chỉ lấy id, name, type từ API — imageUrl để rỗng vì API chưa trả
  factory SearchLocationModel.fromJson(Map<String, dynamic> json) {
    return SearchLocationModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      imageUrl: '', // API chưa có field này
      type: json['type'] ?? 'place',
    );
  }

  // Thêm vào class SearchLocationModel, bên dưới fromJson hiện tại

  /// Parse từ local storage (có imageUrl)
  factory SearchLocationModel.fromLocalJson(Map<String, dynamic> json) {
    return SearchLocationModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      type: json['type'] ?? 'city',
    );
  }

  SearchLocation toEntity() {
    return SearchLocation(
      id: id,
      name: name,
      imageUrl: imageUrl,
      type: type,
    );
  }
}