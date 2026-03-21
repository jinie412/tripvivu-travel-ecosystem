
enum ActivityType { itinerary, rated, reviewPending, food }
enum ActivityStatus { none, upcoming, preparing, delivered, pendingReview }

class ActivityItemEntity {
  final String id;
  final String title;
  final ActivityType type;
  final double? rating;
  final DateTime? date;
  final ActivityStatus status;
  final String? code;
  final String? restaurantName;
  final List<String>? orderItems;

  const ActivityItemEntity({
    required this.id,
    required this.title,
    required this.type,
    this.rating,
    this.date,
    this.status = ActivityStatus.none,
    this.code,
    this.restaurantName,
    this.orderItems,
  });

  ActivityItemEntity copyWith({
    String? id,
    String? title,
    ActivityType? type,
    double? rating,
    DateTime? date,
    ActivityStatus? status,
    String? code,
    String? restaurantName,
    List<String>? orderItems,
  }) {
    return ActivityItemEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      rating: rating ?? this.rating,
      date: date ?? this.date,
      status: status ?? this.status,
      code: code ?? this.code,
      restaurantName: restaurantName ?? this.restaurantName,
      orderItems: orderItems ?? this.orderItems,
    );
  }
}
