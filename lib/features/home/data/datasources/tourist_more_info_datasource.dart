import 'package:travel_advisor_mobile/core/network/dio_client.dart';
import 'package:travel_advisor_mobile/core/utils/auth_utils.dart';
import 'package:travel_advisor_mobile/features/home/data/models/tourist_order_model.dart';

class TouristMoreInfoDataSource {
  final DioClient _client;

  TouristMoreInfoDataSource(this._client);

  Future<List<TouristOrderSummary>> getOrders({int? limit}) async {
    final touristId = await AuthUtils.requireCurrentUserId();
    final response = await _client.dio.get(
      '/more-info/orders',
      queryParameters: {'tourist_id': touristId},
    );

    final data = response.data as Map<String, dynamic>;
    final ordersRaw = data['orders'];
    final orders = ordersRaw is List
        ? ordersRaw
            .whereType<Map<String, dynamic>>()
            .map(TouristOrderSummary.fromJson)
            .toList()
        : <TouristOrderSummary>[];

    if (limit == null || orders.length <= limit) return orders;
    return orders.take(limit).toList();
  }

  Future<TouristOrderDetail> getOrderDetail(String orderId) async {
    final touristId = await AuthUtils.requireCurrentUserId();
    final response = await _client.dio.get(
      '/more-info/orders/$orderId',
      queryParameters: {'tourist_id': touristId},
    );

    return TouristOrderDetail.fromJson(response.data as Map<String, dynamic>);
  }
}
