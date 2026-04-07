// lib/features/search/data/datasources/search_remote_datasource.dart

import 'package:travel_advisor_mobile/core/network/dio_client.dart';
import 'package:travel_advisor_mobile/features/search/data/models/search_location_model.dart';

abstract class SearchRemoteDataSource {
  Future<List<SearchLocationModel>> searchAutocomplete(String query);
  Future<List<SearchLocationModel>> getPlacesByFilter(String city, String category);
}

class SearchRemoteDataSourceImpl implements SearchRemoteDataSource {
  final DioClient dioClient;

  SearchRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<SearchLocationModel>> searchAutocomplete(String query) async {
    final response = await dioClient.dio.get(
      '/search/autocomplete',
      queryParameters: {'q': query},
    );

    // Response là List trực tiếp: [{"id":..., "name":..., "type":..., "score":...}]
    final List<dynamic> data = response.data;
    return data.map((item) => SearchLocationModel.fromJson(item)).toList();
  }

  @override
  Future<List<SearchLocationModel>> getPlacesByFilter(
      String city, String category) async {
    final response = await dioClient.dio.get(
      '/search/filter',
      queryParameters: {'city': city, 'category': category},
    );

    final List<dynamic> data = response.data;
    return data.map((item) => SearchLocationModel.fromJson(item)).toList();
  }
}