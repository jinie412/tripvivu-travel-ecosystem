// lib/features/search/data/datasources/search_local_datasource.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travel_advisor_mobile/features/search/data/models/search_location_model.dart';

abstract class SearchLocalDataSource {
  Future<List<SearchLocationModel>> getRecentSearches();
  Future<void> saveRecentSearch(SearchLocationModel location);
  Future<void> clearRecentSearches();
}

class SearchLocalDataSourceImpl implements SearchLocalDataSource {
  static const String _key = 'recent_searches';
  static const int _maxItems = 10; // Giới hạn tối đa 10 mục

  final SharedPreferences sharedPreferences;

  SearchLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<SearchLocationModel>> getRecentSearches() async {
    final jsonList = sharedPreferences.getStringList(_key) ?? [];
    return jsonList.map((jsonStr) {
      final map = json.decode(jsonStr) as Map<String, dynamic>;
      return SearchLocationModel.fromLocalJson(map);
    }).toList();
  }

  @override
  Future<void> saveRecentSearch(SearchLocationModel location) async {
    final jsonList = sharedPreferences.getStringList(_key)?.toList() ?? [];

    // Tạo JSON string cho location mới
    final newItem = json.encode({
      'id': location.id,
      'name': location.name,
      'imageUrl': location.imageUrl,
      'type': location.type,
    });

    // Xoá nếu đã tồn tại (tránh trùng), rồi thêm lên đầu
    jsonList.removeWhere((item) {
      final map = json.decode(item);
      return map['id'] == location.id;
    });
    jsonList.insert(0, newItem);

    // Giới hạn số lượng
    if (jsonList.length > _maxItems) {
      jsonList.removeRange(_maxItems, jsonList.length);
    }

    await sharedPreferences.setStringList(_key, jsonList);
  }

  @override
  Future<void> clearRecentSearches() async {
    await sharedPreferences.remove(_key);
  }
}