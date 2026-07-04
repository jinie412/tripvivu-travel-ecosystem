// lib/features/search/data/datasources/search_remote_datasource.dart

import 'package:dio/dio.dart';
import 'package:travel_advisor_mobile/core/network/dio_client.dart';
import 'package:travel_advisor_mobile/features/city_detail/data/models/city_models.dart';
import 'package:travel_advisor_mobile/features/city_detail/domain/entities/city_entities.dart';
import 'package:travel_advisor_mobile/features/search/data/models/search_location_model.dart';
import 'package:travel_advisor_mobile/features/search/domain/entities/search_results.dart';

abstract class SearchRemoteDataSource {
  Future<List<SearchLocationModel>> searchAutocomplete(String query);
  Future<List<SearchLocationModel>> getPlacesByFilter(String city, String category);
  Future<SearchMultiResults> searchAll(String query);
  Future<SearchPageResult> searchByType(String query, SearchType type, int page, int limit);
  Future<List<SearchLocationModel>> getRecentSearches(String touristId);
}

class SearchRemoteDataSourceImpl implements SearchRemoteDataSource {
  final DioClient dioClient;

  SearchRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<SearchLocationModel>> searchAutocomplete(String query) async {
    final response = await dioClient.dio.get(
      '/search/autocomplete',
      queryParameters: {'q': query},
      options: Options(
        receiveTimeout: const Duration(seconds: 30),
        extra: dioClient.forceRefreshOptions.extra,
      ),
    );
    final List<dynamic> data = response.data;
    return data.map((item) => SearchLocationModel.fromJson(item)).toList();
  }

  @override
  Future<List<SearchLocationModel>> getPlacesByFilter(
      String city, String category) async {
    final response = await dioClient.dio.get(
      '/search/filter',
      queryParameters: {'city': city, 'category': category},
      options: dioClient.forceRefreshOptions,
    );
    final List<dynamic> data = response.data;
    return data.map((item) => SearchLocationModel.fromJson(item)).toList();
  }

  @override
  Future<SearchMultiResults> searchAll(String query) async {
    final response = await dioClient.dio.get(
      '/search/all',
      queryParameters: {'q': query},
      options: Options(
        receiveTimeout: const Duration(seconds: 45),
        extra: dioClient.forceRefreshOptions.extra,
      ),
    );
    final json = response.data as Map<String, dynamic>;
    return _parseMultiResults(json);
  }

  @override
  Future<List<SearchLocationModel>> getRecentSearches(String touristId) async {
    final response = await dioClient.dio.get(
      '/activity/recent-searches',
      options: dioClient.forceRefreshOptions,
    );
    final List<dynamic> data = response.data;
    return data.map((item) => SearchLocationModel.fromJson(item)).toList();
  }

  @override
  Future<SearchPageResult> searchByType(
      String query, SearchType type, int page, int limit) async {
    final response = await dioClient.dio.get(
      '/search/results',
      queryParameters: {
        'q': query,
        'type': _typeToString(type),
        'page': page,
        'limit': limit,
      },
      options: dioClient.forceRefreshOptions,
    );
    final json = response.data as Map<String, dynamic>;
    final rawData = (json['data'] as List<dynamic>?) ?? [];
    return SearchPageResult(
      data: _parseByType(rawData, type),
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? page,
      pages: (json['pages'] as num?)?.toInt() ?? 1,
    );
  }

  String _typeToString(SearchType type) {
    switch (type) {
      case SearchType.itinerary:
        return 'itinerary';
      case SearchType.activity:
        return 'activity';
      case SearchType.restaurant:
        return 'restaurant';
      case SearchType.hotel:
        return 'hotel';
    }
  }

  SearchMultiResults _parseMultiResults(Map<String, dynamic> json) {
    final itinRaw = json['itineraries'] as Map<String, dynamic>? ?? {};
    final actRaw = json['activities'] as Map<String, dynamic>? ?? {};
    final resRaw = json['restaurants'] as Map<String, dynamic>? ?? {};
    final hotRaw = json['hotels'] as Map<String, dynamic>? ?? {};

    final itinList = (itinRaw['data'] as List<dynamic>?) ?? [];
    final actList = (actRaw['data'] as List<dynamic>?) ?? [];
    final resList = (resRaw['data'] as List<dynamic>?) ?? [];
    final hotList = (hotRaw['data'] as List<dynamic>?) ?? [];

    final cityById = <String, String>{};
    for (final raw in [...actList, ...resList, ...hotList]) {
      if (raw is Map<String, dynamic>) {
        final id = raw['id'] as String? ?? '';
        final city = raw['city'] as String? ?? '';
        if (id.isNotEmpty && city.isNotEmpty) cityById[id] = city;
      }
    }
    for (final raw in itinList) {
      if (raw is Map<String, dynamic>) {
        final id = raw['id'] as String? ?? '';
        final dest = raw['destination'] as String? ?? '';
        if (id.isNotEmpty && dest.isNotEmpty) cityById[id] = dest;
      }
    }

    return SearchMultiResults(
      itineraries: SearchTypeCount(
        data: _parseItineraries(itinList),
        total: (itinRaw['total'] as num?)?.toInt() ?? 0,
      ),
      activities: SearchTypeCount(
        data: _parseActivities(actList),
        total: (actRaw['total'] as num?)?.toInt() ?? 0,
      ),
      restaurants: SearchTypeCount(
        data: _parseRestaurants(resList),
        total: (resRaw['total'] as num?)?.toInt() ?? 0,
      ),
      hotels: SearchTypeCount(
        data: _parseHotels(hotList),
        total: (hotRaw['total'] as num?)?.toInt() ?? 0,
      ),
      cityById: cityById,
    );
  }

  List<dynamic> _parseByType(List<dynamic> raw, SearchType type) {
    switch (type) {
      case SearchType.itinerary:
        return _parseItineraries(raw);
      case SearchType.activity:
        return _parseActivities(raw);
      case SearchType.restaurant:
        return _parseRestaurants(raw);
      case SearchType.hotel:
        return _parseHotels(raw);
    }
  }

  List<CityItinerary> _parseItineraries(List<dynamic> raw) => raw
      .whereType<Map<String, dynamic>>()
      .map((item) => CityItineraryModel.fromJson(item).toEntity())
      .toList();

  List<CityActivity> _parseActivities(List<dynamic> raw) => raw
      .whereType<Map<String, dynamic>>()
      .map((item) => CityActivityModel.fromJson(_normalizeActivity(item)).toEntity())
      .toList();

  List<CityRestaurant> _parseRestaurants(List<dynamic> raw) => raw
      .whereType<Map<String, dynamic>>()
      .map((item) => CityRestaurantModel.fromJson(_normalizeRestaurant(item)).toEntity())
      .toList();

  List<CityHotel> _parseHotels(List<dynamic> raw) => raw
      .whereType<Map<String, dynamic>>()
      .map((item) => CityHotelModel.fromJson(_normalizeHotel(item)).toEntity())
      .toList();

  Map<String, dynamic> _normalizeActivity(Map<String, dynamic> item) => {
        'id': _readString(item['id']),
        'name': _readString(item['name'] ?? item['title']),
        'imageUrl': _readString(item['imageUrl'] ?? item['image_url'] ?? item['image']),
        'rating': _readDouble(item['rating'] ?? item['average_rating']),
        'reviewCount': _readInt(item['reviewCount'] ?? item['review_count']),
        'address': _readString(item['address'] ?? item['city'] ?? item['location']),
        'status': _readStatus(item['status']),
        'isFavorite': item['isFavorite'] == true || item['is_favorite'] == true,
        'category': _readString(item['category']),
        'priceType': _readString(item['priceType'] ?? item['price_type']),
        'district': _readString(item['district']),
      };

  Map<String, dynamic> _normalizeRestaurant(Map<String, dynamic> item) => {
        'id': _readString(item['id']),
        'name': _readString(item['name']),
        'imageUrl': _readString(item['imageUrl'] ?? item['image_url'] ?? item['image']),
        'rating': _readDouble(item['rating'] ?? item['average_rating']),
        'reviewCount': _readInt(item['reviewCount'] ?? item['review_count']),
        'address': _readString(item['address'] ?? item['city'] ?? item['location']),
        'status': _readStatus(item['status']),
        'isFavorite': item['isFavorite'] == true || item['is_favorite'] == true,
        'cuisine': _readString(item['cuisine']),
        'priceLevel': _readString(item['priceLevel'] ?? item['price_level']),
        'amenities': _readStringList(item['amenities']),
      };

  Map<String, dynamic> _normalizeHotel(Map<String, dynamic> item) => {
        'id': _readString(item['id']),
        'name': _readString(item['name']),
        'imageUrl': _readString(item['imageUrl'] ?? item['image_url'] ?? item['image']),
        'rating': _readDouble(item['rating'] ?? item['average_rating']),
        'reviewCount': _readInt(item['reviewCount'] ?? item['review_count']),
        'address': _readString(item['address'] ?? item['city'] ?? item['location']),
        'status': _readStatus(item['status']),
        'price': _readString(item['price']).isNotEmpty
            ? _readString(item['price'])
            : 'Liên hệ',
        'isFavorite': item['isFavorite'] == true || item['is_favorite'] == true,
        'starRating': _readInt(item['starRating'] ?? item['star_rating']),
        'priceValue': _readDouble(item['priceValue'] ?? item['price_value'] ?? item['price']),
        'accommodationType':
            _readString(item['accommodationType'] ?? item['accommodation_type']),
        'amenities': _readStringList(item['amenities']),
      };

  String _readString(dynamic value) => value?.toString().trim() ?? '';

  int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _readDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _readStatus(dynamic value) {
    final status = _readString(value);
    return status == 'Chưa có giờ mở cửa' ? '' : status;
  }

  List<String> _readStringList(dynamic value) {
    if (value is! List) return const <String>[];
    return value.map((item) => item.toString()).toList();
  }
}
