import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

import 'package:travel_advisor_mobile/core/config/app_config.dart';
import 'package:travel_advisor_mobile/core/error/region_allocation_required_exception.dart';
import 'package:travel_advisor_mobile/core/theme/app_colors.dart';

/// Palette đánh số cho pin/vùng — tách riêng khỏi `kDayColors` của itinerary
/// map (vùng địa lý ở bước này không map 1-1 với ngày lịch trình cuối cùng,
/// gán trùng bảng màu dễ gây hiểu nhầm).
const List<Color> _kRegionMarkerColors = [
  Color(0xFF1A6EBD),
  Color(0xFF16A34A),
  Color(0xFF7C3AED),
  Color(0xFFCA8A04),
  Color(0xFF0891B2),
  Color(0xFFE11D48),
];

/// Map View cho màn phân bổ vùng — mỗi vùng vẽ thành 1 vòng tròn phủ mờ
/// quanh tâm cụm thay vì chỉ 1 chấm nhỏ, để người dùng hình dung được phạm
/// vi/ranh giới thực tế thay vì phải suy luận từ 1 điểm. Bán kính tính từ
/// điểm xa nhất trong `boundary` (convex hull backend đã tính) tới tâm —
/// dùng hình tròn thay vì vẽ nguyên hull vì hull nhiều cạnh gấp khúc nhìn
/// rối, trong khi hình tròn vẫn phản ánh đúng độ "rộng" của vùng mà dễ nhìn
/// hơn. Vùng không đủ dữ liệu để dựng hull (`hasBoundary == false`, ví dụ
/// chỉ có 1-2 địa điểm) vẫn hiện pin đánh số tại tâm cụm như cũ. Bấm vào
/// vòng tròn hoặc pin đều mở thẻ chi tiết + stepper của vùng đó qua
/// [onRegionTap], thay vì nhân bản UI stepper lên trên bản đồ.
class RegionAllocationMapView extends StatefulWidget {
  final List<RegionInfo> regions;
  final ValueChanged<int> onRegionTap;

  const RegionAllocationMapView({
    super.key,
    required this.regions,
    required this.onRegionTap,
  });

  @override
  State<RegionAllocationMapView> createState() =>
      _RegionAllocationMapViewState();
}

class _RegionAllocationMapViewState extends State<RegionAllocationMapView>
    implements
        mapbox.OnPointAnnotationClickListener,
        mapbox.OnPolygonAnnotationClickListener {
  mapbox.MapboxMap? _mapboxMap;
  mapbox.PointAnnotationManager? _pointAnnotationManager;
  mapbox.PolygonAnnotationManager? _polygonAnnotationManager;
  final Map<String, int> _pointRegionIndex = {};
  final Map<String, int> _polygonRegionIndex = {};

  List<int> get _regionsWithCentroid => [
    for (var i = 0; i < widget.regions.length; i++)
      if (widget.regions[i].hasCentroid) i,
  ];

  Color _colorFor(int i, RegionInfo region) => region.isRemote
      ? const Color(0xFFB45309)
      : _kRegionMarkerColors[i % _kRegionMarkerColors.length];

  @override
  Widget build(BuildContext context) {
    if (_regionsWithCentroid.isEmpty) {
      return Container(
        color: AppColors.premiumBackground,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(32),
        child: const Text(
          'Chưa có dữ liệu tọa độ để hiển thị bản đồ cho các vùng này.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      );
    }

    final first = widget.regions[_regionsWithCentroid.first];
    return mapbox.MapWidget(
      key: const ValueKey('region_allocation_map'),
      styleUri: AppConfig.kGoongMapStyle,
      cameraOptions: mapbox.CameraOptions(
        center: mapbox.Point(
          coordinates: mapbox.Position(first.centroidLng!, first.centroidLat!),
        ),
        zoom: 11.0,
      ),
      onMapCreated: (map) => _mapboxMap = map,
      onStyleLoadedListener: _onStyleLoaded,
    );
  }

  Future<void> _onStyleLoaded(mapbox.StyleLoadedEventData event) async {
    if (!mounted || _mapboxMap == null) return;
    try {
      // Polygon manager được tạo TRƯỚC point manager để layer vùng nằm dưới,
      // pin đánh số luôn nổi lên trên phần fill.
      _polygonAnnotationManager = await _mapboxMap!.annotations
          .createPolygonAnnotationManager();
      if (!mounted) return;
      _polygonAnnotationManager!.addOnPolygonAnnotationClickListener(this);
      _pointAnnotationManager = await _mapboxMap!.annotations
          .createPointAnnotationManager();
      if (!mounted) return;
      _pointAnnotationManager!.addOnPointAnnotationClickListener(this);
      await _drawRegions();
      if (!mounted) return;
      await _fitCameraToMarkers();
    } catch (e) {
      // Widget này có thể bị dispose (đổi tab, pop route) trong lúc các
      // lệnh tạo/vẽ annotation ở trên còn đang await dở trên native
      // channel — lúc đó gọi tiếp vào manager/mapboxMap sẽ ném
      // PlatformException. Nuốt lỗi ở đây thay vì để nó văng ra ngoài
      // async gap (không ai catch được, Flutter sẽ báo lỗi không rõ
      // nguyên nhân ở màn hình kế tiếp).
      debugPrint('RegionAllocationMapView draw error: $e');
    }
  }

  Future<void> _drawRegions() async {
    if (_pointAnnotationManager == null || _polygonAnnotationManager == null) {
      return;
    }
    for (final i in _regionsWithCentroid) {
      if (!mounted) return;
      final region = widget.regions[i];
      final color = _colorFor(i, region);

      if (region.hasBoundary) {
        final centerLat = region.centroidLat!;
        final centerLng = region.centroidLng!;
        final radiusKm = region.boundary!
            .map((p) => _haversineKm(centerLat, centerLng, p[0], p[1]))
            .fold<double>(0, math.max);
        // Sàn tối thiểu để cụm rất gọn (vài địa điểm sát nhau) vẫn hiện 1
        // vòng tròn thấy được thay vì gần như biến mất.
        final circlePoints = _circlePoints(
          centerLat,
          centerLng,
          radiusKm < 0.15 ? 0.15 : radiusKm,
        );
        final ring = [
          for (final point in circlePoints)
            mapbox.Point(coordinates: mapbox.Position(point[1], point[0])),
        ];
        final polygon = await _polygonAnnotationManager!.create(
          mapbox.PolygonAnnotationOptions(
            geometry: mapbox.Polygon.fromPoints(points: [ring]),
            fillColor: color.toARGB32(),
            fillOpacity: 0.22,
            fillOutlineColor: color.toARGB32(),
          ),
        );
        if (!mounted) return;
        _polygonRegionIndex[polygon.id] = i;
      }

      if (!mounted) return;
      final icon = await _createRegionMarker(i + 1, color);
      if (!mounted) return;
      final annotation = await _pointAnnotationManager!.create(
        mapbox.PointAnnotationOptions(
          geometry: mapbox.Point(
            coordinates: mapbox.Position(
              region.centroidLng!,
              region.centroidLat!,
            ),
          ),
          image: icon,
          iconSize: 1.0,
        ),
      );
      if (!mounted) return;
      _pointRegionIndex[annotation.id] = i;
    }
  }

  Future<void> _fitCameraToMarkers() async {
    if (!mounted || _mapboxMap == null) return;
    final points = [
      for (final i in _regionsWithCentroid)
        mapbox.Point(
          coordinates: mapbox.Position(
            widget.regions[i].centroidLng!,
            widget.regions[i].centroidLat!,
          ),
        ),
    ];
    if (points.length == 1) {
      await _mapboxMap!.easeTo(
        mapbox.CameraOptions(center: points.first, zoom: 12.5),
        mapbox.MapAnimationOptions(duration: 700),
      );
      return;
    }
    final camera = await _mapboxMap!.cameraForCoordinates(
      points,
      mapbox.MbxEdgeInsets(top: 80, left: 56, bottom: 80, right: 56),
      null,
      null,
    );
    if (!mounted) return;
    double zoom = camera.zoom ?? 11.0;
    if (zoom < 4.5) zoom = 4.5;
    await _mapboxMap!.easeTo(
      mapbox.CameraOptions(
        center: camera.center,
        zoom: zoom,
        padding: camera.padding,
      ),
      mapbox.MapAnimationOptions(duration: 700),
    );
  }

  static const double _kEarthRadiusKm = 6371.0;

  double _degToRad(double deg) => deg * math.pi / 180;
  double _radToDeg(double rad) => rad * 180 / math.pi;

  double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return _kEarthRadiusKm * c;
  }

  /// Sinh các điểm [lat, lng] tạo thành 1 vòng tròn địa lý bán kính
  /// `radiusKm` quanh tâm — dùng công thức "destination point given
  /// bearing" thay vì offset tuyến tính, để vòng tròn không bị méo khi vùng
  /// nằm xa xích đạo. Điểm đầu (bearing 0°) và điểm cuối (bearing 360°)
  /// trùng nhau nên ring GeoJSON tự đóng, không cần nối thủ công.
  List<List<double>> _circlePoints(
    double centerLat,
    double centerLng,
    double radiusKm, {
    int segments = 48,
  }) {
    final centerLatRad = _degToRad(centerLat);
    final centerLngRad = _degToRad(centerLng);
    final angularDistance = radiusKm / _kEarthRadiusKm;
    final points = <List<double>>[];
    for (var i = 0; i <= segments; i++) {
      final bearing = _degToRad(360 * i / segments);
      final lat2 = math.asin(
        math.sin(centerLatRad) * math.cos(angularDistance) +
            math.cos(centerLatRad) *
                math.sin(angularDistance) *
                math.cos(bearing),
      );
      final lng2 = centerLngRad +
          math.atan2(
            math.sin(bearing) * math.sin(angularDistance) * math.cos(centerLatRad),
            math.cos(angularDistance) - math.sin(centerLatRad) * math.sin(lat2),
          );
      points.add([_radToDeg(lat2), _radToDeg(lng2)]);
    }
    return points;
  }

  Future<Uint8List> _createRegionMarker(int number, Color color) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = ui.Size(96, 96);
    final center = Offset(size.width / 2, size.height / 2);

    canvas.drawCircle(
      center.translate(0, 3),
      32,
      Paint()..color = Colors.black.withValues(alpha: 0.22),
    );
    canvas.drawCircle(center, 30, Paint()..color = color);
    canvas.drawCircle(
      center,
      30,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    final numberText = TextPainter(
      text: TextSpan(
        text: '$number',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    numberText.layout();
    numberText.paint(
      canvas,
      Offset(
        center.dx - numberText.width / 2,
        center.dy - numberText.height / 2,
      ),
    );

    final img = await recorder.endRecording().toImage(96, 96);
    return (await img.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
  }

  @override
  bool onPointAnnotationClick(mapbox.PointAnnotation annotation) {
    final index = _pointRegionIndex[annotation.id];
    if (index != null) widget.onRegionTap(index);
    return true;
  }

  @override
  bool onPolygonAnnotationClick(mapbox.PolygonAnnotation annotation) {
    final index = _polygonRegionIndex[annotation.id];
    if (index != null) widget.onRegionTap(index);
    return true;
  }
}
