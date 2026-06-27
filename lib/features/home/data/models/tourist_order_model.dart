class TouristOrderSummary {
  final String orderId;
  final String orderCode;
  final String restaurantName;
  final String status;
  final String statusLabel;
  final DateTime? orderedAt;
  final double totalAmount;

  const TouristOrderSummary({
    required this.orderId,
    required this.orderCode,
    required this.restaurantName,
    required this.status,
    required this.statusLabel,
    required this.orderedAt,
    required this.totalAmount,
  });

  factory TouristOrderSummary.fromJson(Map<String, dynamic> json) {
    final orderedAtRaw = json['ordered_at']?.toString();
    return TouristOrderSummary(
      orderId: (json['order_id'] ?? '').toString(),
      orderCode: (json['order_code'] ?? '').toString(),
      restaurantName: (json['restaurant_name'] ?? 'Quán ăn').toString(),
      status: (json['status'] ?? 'processing').toString(),
      statusLabel: (json['status_label'] ?? 'Đang chuẩn bị').toString(),
      orderedAt: orderedAtRaw == null || orderedAtRaw.isEmpty
          ? null
          : DateTime.tryParse(orderedAtRaw),
      totalAmount: ((json['total_amount'] as num?) ?? 0).toDouble(),
    );
  }
}

class TouristOrderItem {
  final String id;
  final String foodItemId;
  final String name;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  const TouristOrderItem({
    required this.id,
    required this.foodItemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory TouristOrderItem.fromJson(Map<String, dynamic> json) {
    return TouristOrderItem(
      id: (json['id'] ?? '').toString(),
      foodItemId: (json['food_item_id'] ?? '').toString(),
      name: (json['name'] ?? 'Món ăn').toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: ((json['unit_price'] as num?) ?? 0).toDouble(),
      totalPrice: ((json['total_price'] as num?) ?? 0).toDouble(),
    );
  }
}

class TouristOrderDetail {
  final TouristOrderSummary order;
  final List<TouristOrderItem> items;

  const TouristOrderDetail({
    required this.order,
    required this.items,
  });

  factory TouristOrderDetail.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'];
    return TouristOrderDetail(
      order: TouristOrderSummary.fromJson(
        (json['order'] as Map<String, dynamic>?) ?? const {},
      ),
      items: itemsRaw is List
          ? itemsRaw
              .whereType<Map<String, dynamic>>()
              .map(TouristOrderItem.fromJson)
              .toList()
          : const [],
    );
  }
}
