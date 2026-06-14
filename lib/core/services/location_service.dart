import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

import 'package:travel_advisor_mobile/features/home/domain/entities/user_location.dart';

/// Lỗi khi lấy vị trí. [permissionDenied] = true khi người dùng từ chối quyền
/// hoặc dịch vụ vị trí đang tắt (UI nên gợi ý mở cài đặt).
class LocationFailure implements Exception {
  final String message;
  final bool permissionDenied;
  const LocationFailure(this.message, {this.permissionDenied = false});

  @override
  String toString() => message;
}

/// Lấy vị trí hiện tại của thiết bị và reverse-geocode ra Phường/Xã, Tỉnh/TP.
///
/// - Quyền vị trí: dùng `geolocator` (hiển thị hộp thoại xin quyền hệ thống).
/// - Reverse geocoding: Nominatim (OpenStreetMap) — miễn phí, không cần API key,
///   `accept-language=vi` để trả tên tiếng Việt. Có hỗ trợ CORS nên chạy được
///   cả web lẫn mobile.
class LocationService {
  final Dio _dio;

  LocationService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  static const _nominatimUrl = 'https://nominatim.openstreetmap.org/reverse';

  Future<UserLocation> getCurrentLocation() async {
    final position = await _resolvePosition();
    final geo = await _reverseGeocode(position.latitude, position.longitude);
    return UserLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      ward: geo.$1,
      province: geo.$2,
    );
  }

  /// Stream vị trí realtime — emit khi người dùng di chuyển >= [distanceFilter] m.
  /// Yêu cầu quyền/dịch vụ đã được cấp (kiểm tra trước qua [getCurrentLocation]).
  ///
  /// Mặc định dùng `medium` accuracy: tên Phường/Xã chỉ đổi sau hàng trăm mét
  /// nên không cần GPS chính xác cao -> tiết kiệm pin.
  Stream<Position> positionStream({int distanceFilter = 100}) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: distanceFilter,
      ),
    );
  }

  /// Reverse-geocode một toạ độ ra (ward, province) — public để cubit gọi lại
  /// khi vị trí thay đổi mà không cần lấy lại GPS.
  Future<UserLocation> reverseGeocode(double lat, double lng) async {
    final geo = await _reverseGeocode(lat, lng);
    return UserLocation(
      latitude: lat,
      longitude: lng,
      ward: geo.$1,
      province: geo.$2,
    );
  }

  /// Kiểm tra dịch vụ + quyền, rồi lấy toạ độ hiện tại.
  Future<Position> _resolvePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationFailure(
        'Dịch vụ vị trí đang tắt. Vui lòng bật GPS để xác định vị trí.',
        permissionDenied: true,
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationFailure(
        'Bạn đã từ chối quyền truy cập vị trí.',
        permissionDenied: true,
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationFailure(
        'Quyền vị trí bị từ chối vĩnh viễn. Hãy cấp quyền trong Cài đặt.',
        permissionDenied: true,
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  /// Trả về (ward, province). Phần nào không xác định được sẽ là null.
  Future<(String?, String?)> _reverseGeocode(double lat, double lng) async {
    try {
      final res = await _dio.get(
        _nominatimUrl,
        queryParameters: {
          'lat': lat,
          'lon': lng,
          'format': 'jsonv2',
          'accept-language': 'vi',
          'addressdetails': 1,
          'zoom': 18,
        },
        options: Options(
          // Nominatim yêu cầu User-Agent định danh ứng dụng (trên web trình
          // duyệt sẽ bỏ qua header này và tự gắn UA của nó — vẫn hợp lệ).
          headers: {'User-Agent': 'GPTravelAdvisor/1.0 (thesis app)'},
        ),
      );

      final data = res.data;
      final address = (data is Map ? data['address'] : null) as Map?;
      if (address == null) return (null, null);

      String? pick(List<String> keys) {
        for (final k in keys) {
          final v = address[k];
          if (v is String && v.trim().isNotEmpty) return v.trim();
        }
        return null;
      }

      // Phường/Xã (cấp cơ sở ở VN theo dữ liệu OSM).
      final ward = pick([
        'quarter',
        'ward',
        'suburb',
        'neighbourhood',
        'village',
        'hamlet',
        'town',
      ]);
      // Tỉnh/Thành phố trực thuộc TW.
      final province = pick(['state', 'city', 'region', 'county']);

      return (ward, province);
    } on DioException {
      // Mạng lỗi -> trả null, cubit vẫn coi là Loaded với toạ độ.
      return (null, null);
    }
  }
}
