import 'package:equatable/equatable.dart';

/// Vị trí hiện tại của người dùng (đã reverse-geocode).
/// [ward] = Phường/Xã, [province] = Tỉnh/Thành phố.
class UserLocation extends Equatable {
  final double latitude;
  final double longitude;
  final String? ward; // Phường/Xã
  final String? province; // Tỉnh/Thành phố

  const UserLocation({
    required this.latitude,
    required this.longitude,
    this.ward,
    this.province,
  });

  /// Chuỗi hiển thị "Phường/Xã, Tỉnh/TP" (in hoa), bỏ phần rỗng.
  String get displayText {
    final parts = [ward, province]
        .where((e) => e != null && e.trim().isNotEmpty)
        .map((e) => e!.trim())
        .toList();
    if (parts.isEmpty) return 'KHÔNG XÁC ĐỊNH VỊ TRÍ';
    return parts.join(', ').toUpperCase();
  }

  @override
  List<Object?> get props => [latitude, longitude, ward, province];
}
