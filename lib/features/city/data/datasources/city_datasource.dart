import 'package:travel_advisor_mobile/core/network/dio_client.dart';
import 'package:travel_advisor_mobile/features/city/domain/entities/city_entity.dart';

abstract class CityDataSource {
  Future<List<CityEntity>> searchCities(String query);
}

class RemoteCityDataSource implements CityDataSource {
  final DioClient _client;
  RemoteCityDataSource(this._client);

  @override
  Future<List<CityEntity>> searchCities(String query) async {
    final params = query.trim().isEmpty ? <String, dynamic>{} : {'search': query.trim()};
    final res = await _client.dio.get('/cities', queryParameters: params);

    final List<dynamic> list = res.data as List<dynamic>;
    return list
        .map((e) => CityEntity(
              id: e['id'] as String,
              name: e['name'] as String,
            ))
        .toList();
  }
}
