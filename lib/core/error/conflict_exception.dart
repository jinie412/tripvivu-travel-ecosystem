class ConflictException implements Exception {
  final String message;
  final bool canExtend;
  final bool canReduce;
  final bool canAddDay;

  ConflictException({
    required this.message,
    this.canExtend = false,
    this.canReduce = false,
    this.canAddDay = false,
  });

  factory ConflictException.fromJson(Map<String, dynamic> json) {
    return ConflictException(
      message: json['message'] ?? 'Xung đột thời gian',
      canExtend: json['canExtend'] ?? false,
      canReduce: json['canReduce'] ?? false,
      canAddDay: json['canAddDay'] ?? false,
    );
  }

  @override
  String toString() => message;
}
