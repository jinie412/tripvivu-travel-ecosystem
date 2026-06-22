import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:travel_advisor_mobile/core/config/app_config.dart';
import 'package:travel_advisor_mobile/core/constants/app_colors.dart';
import 'package:travel_advisor_mobile/core/utils/map_utils.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_activity_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_day_entity.dart';

const List<Color> kDayColors = [
  Color(0xFFE11D48),
  Color(0xFFF97316),
  Color(0xFF7C3AED),
  Color(0xFF0891B2),
  Color(0xFF16A34A),
  Color(0xFFCA8A04),
  Color(0xFF334155),
];

const Color kSelectedRouteColor = Color(0xFFE11D48);
const Color kDoneStopColor = Color(0xFF16A34A);

class ItineraryMapView extends StatefulWidget {
  final List<ItineraryActivityEntity> activities;
  final List<ItineraryDayEntity> allDays;
  final int selectedDay;
  final Function(String)? onMarkerTap;
  final Function(mapbox.MapboxMap)? onMapCreated;

  const ItineraryMapView({
    super.key,
    required this.activities,
    required this.allDays,
    required this.selectedDay,
    this.onMarkerTap,
    this.onMapCreated,
  });

  @override
  State<ItineraryMapView> createState() => _ItineraryMapViewState();
}

class _ItineraryMapViewState extends State<ItineraryMapView>
    implements mapbox.OnPointAnnotationClickListener {
  mapbox.MapboxMap? _mapboxMap;
  mapbox.PointAnnotationManager? _pointAnnotationManager;
  mapbox.PolylineAnnotationManager? _polylineAnnotationManager;
  bool _isStyleLoaded = false;
  bool _showAllDays = false;
  mapbox.Position? _userPosition;
  final Map<String, String> _annotationIdMap = {};
  final Map<String, List<mapbox.Position>> _routeCache = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        final req = await geo.Geolocator.requestPermission();
        if (req == geo.LocationPermission.denied ||
            req == geo.LocationPermission.deniedForever) {
          debugPrint('Location permission denied');
          return;
        }
      }

      final lastPos = await geo.Geolocator.getLastKnownPosition();
      if (lastPos != null && mounted) {
        setState(() {
          _userPosition = mapbox.Position(lastPos.longitude, lastPos.latitude);
        });
        if (_isStyleLoaded) {
          _updateMapContent();
        }
      }

      final pos = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
        ),
      );

      if (mounted) {
        setState(() {
          _userPosition = mapbox.Position(pos.longitude, pos.latitude);
        });
        if (_isStyleLoaded) {
          _updateMapContent();
        }
      }
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  void _focusOnUser() {
    if (_userPosition == null || _mapboxMap == null) {
      _getCurrentLocation();
      return;
    }

    final points = _currentItineraryPoints(includeUser: true);
    if (points.length > 1) {
      _fitCameraToPoints(points);
      return;
    }

    _mapboxMap?.flyTo(
      mapbox.CameraOptions(
        center: mapbox.Point(coordinates: _userPosition!),
        zoom: 15.0,
      ),
      mapbox.MapAnimationOptions(duration: 900),
    );
  }

  IconData _iconForActivity(ItineraryActivityEntity activity) {
    final category = (activity.category ?? '').toLowerCase();
    final title = activity.title.toLowerCase();
    if (category.contains('ẩm thực') ||
        category.contains('am thuc') ||
        category.contains('nhà hàng') ||
        category.contains('nha hang') ||
        category.contains('restaurant')) {
      return Icons.restaurant_rounded;
    }
    if (category.contains('cafe') ||
        category.contains('cà phê') ||
        category.contains('ca phe') ||
        title.contains('cafe') ||
        title.contains('coffee')) {
      return Icons.local_cafe_rounded;
    }
    if (category.contains('giải trí') ||
        category.contains('giai tri') ||
        category.contains('entertainment')) {
      return Icons.local_activity_rounded;
    }
    return Icons.account_balance_rounded;
  }

  Future<Uint8List> _createStopIcon(
    int number,
    Color bgColor,
    IconData iconData, {
    bool isCompleted = false,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = ui.Size(104, 104);
    final center = Offset(size.width / 2, 52);

    canvas.drawCircle(
      center.translate(0, 3),
      34,
      Paint()..color = Colors.black.withValues(alpha: 0.20),
    );
    canvas.drawCircle(center, 30, Paint()..color = bgColor);
    canvas.drawCircle(
      center,
      30,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5,
    );

    final icon = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          fontFamily: iconData.fontFamily,
          package: iconData.fontPackage,
          color: Colors.white,
          fontSize: 28,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    icon.layout();
    icon.paint(
      canvas,
      Offset((size.width - icon.width) / 2, 38 - icon.height / 2),
    );

    final badgeCenter = Offset(size.width / 2, 79);
    canvas.drawCircle(badgeCenter, 15, Paint()..color = Colors.white);
    canvas.drawCircle(
      badgeCenter,
      15,
      Paint()
        ..color = bgColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final numberText = TextPainter(
      text: TextSpan(
        text: isCompleted
            ? String.fromCharCode(Icons.check_rounded.codePoint)
            : number.toString(),
        style: TextStyle(
          fontFamily: isCompleted ? Icons.check_rounded.fontFamily : null,
          package: isCompleted ? Icons.check_rounded.fontPackage : null,
          color: bgColor,
          fontSize: isCompleted ? 20 : 17,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    numberText.layout();
    numberText.paint(
      canvas,
      Offset(
        badgeCenter.dx - numberText.width / 2,
        badgeCenter.dy - numberText.height / 2,
      ),
    );

    final img = await recorder.endRecording().toImage(104, 104);
    return (await img.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
  }

  Future<Uint8List> _createHotelIcon() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = ui.Size(96, 96);
    final center = Offset(size.width / 2, size.height / 2);

    canvas.drawCircle(
      center.translate(0, 3),
      38,
      Paint()..color = Colors.black.withValues(alpha: 0.24),
    );
    canvas.drawCircle(center, 34, Paint()..color = const Color(0xFF0F766E));
    canvas.drawCircle(
      center,
      34,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    const icon = Icons.hotel_rounded;
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: Colors.white,
          fontSize: 38,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(
      canvas,
      Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2),
    );

    final img = await recorder.endRecording().toImage(96, 96);
    return (await img.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
  }

  Future<Uint8List> _createDayStopIcon(
    int day,
    int number,
    Color color,
    IconData iconData, {
    bool isCompleted = false,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawCircle(
      const Offset(52, 55),
      34,
      Paint()..color = Colors.black.withValues(alpha: 0.18),
    );
    canvas.drawCircle(const Offset(52, 52), 30, Paint()..color = color);
    canvas.drawCircle(
      const Offset(52, 52),
      30,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5,
    );

    final icon = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          fontFamily: iconData.fontFamily,
          package: iconData.fontPackage,
          color: Colors.white,
          fontSize: 25,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    icon.layout();
    icon.paint(canvas, Offset(52 - icon.width / 2, 39 - icon.height / 2));

    const badgeCenter = Offset(52, 80);
    canvas.drawCircle(badgeCenter, 16, Paint()..color = Colors.white);
    canvas.drawCircle(
      badgeCenter,
      16,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final tp = TextPainter(
      text: TextSpan(
        text: '$day.$number',
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(52 - tp.width / 2, 80 - tp.height / 2));

    final img = await recorder.endRecording().toImage(104, 104);
    return (await img.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
  }

  Future<Uint8List> _createDayHotelIcon(int day, Color color) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawCircle(
      const Offset(48, 51),
      38,
      Paint()..color = Colors.black.withValues(alpha: 0.24),
    );
    canvas.drawCircle(
      const Offset(48, 48),
      34,
      Paint()..color = const Color(0xFF0F766E),
    );
    canvas.drawCircle(
      const Offset(48, 48),
      34,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    const icon = Icons.hotel_rounded;
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: Colors.white,
          fontSize: 28,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset((96 - tp.width) / 2, (96 - tp.height) / 2 - 3));

    final label = TextPainter(
      text: TextSpan(
        text: 'D$day',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    label.layout();
    label.paint(canvas, Offset((96 - label.width) / 2, 66));

    final img = await recorder.endRecording().toImage(96, 96);
    return (await img.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
  }

  Future<Uint8List> _createCurrentLocationIcon() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawCircle(
      const Offset(64, 64),
      56,
      Paint()..color = const Color(0xFF2563EB).withValues(alpha: 0.22),
    );
    canvas.drawCircle(const Offset(64, 64), 38, Paint()..color = Colors.white);
    canvas.drawCircle(
      const Offset(64, 64),
      30,
      Paint()..color = const Color(0xFF2563EB),
    );
    canvas.drawCircle(const Offset(64, 64), 12, Paint()..color = Colors.white);
    canvas.drawCircle(
      const Offset(64, 64),
      56,
      Paint()
        ..color = const Color(0xFF2563EB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );

    final img = await recorder.endRecording().toImage(128, 128);
    return (await img.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
  }

  Future<Uint8List> _createRouteArrowIcon(Color color) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final path = Path()
      ..moveTo(36, 10)
      ..lineTo(58, 54)
      ..lineTo(36, 43)
      ..lineTo(14, 54)
      ..close();

    canvas.drawPath(
      path.shift(const Offset(0, 3)),
      Paint()..color = Colors.black.withValues(alpha: 0.28),
    );
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    final img = await recorder.endRecording().toImage(72, 72);
    return (await img.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
  }

  Future<Uint8List> _createClusterIcon(int count, Color color) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const center = Offset(48, 48);

    canvas.drawCircle(
      center.translate(0, 3),
      34,
      Paint()..color = Colors.black.withValues(alpha: 0.18),
    );
    canvas.drawCircle(
      center,
      31,
      Paint()..color = color.withValues(alpha: 0.92),
    );
    canvas.drawCircle(
      center,
      31,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(48 - tp.width / 2, 48 - tp.height / 2));

    final img = await recorder.endRecording().toImage(96, 96);
    return (await img.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
  }

  bool _isHotelStart(ItineraryActivityEntity activity) {
    final category = (activity.category ?? '').toLowerCase();
    final title = activity.title.toLowerCase();
    final sameTime = activity.startTime == activity.endTime;
    return sameTime &&
        (category.contains('lưu trú') ||
            category.contains('luu tru') ||
            category.contains('khách sạn') ||
            category.contains('khach san') ||
            category.contains('hotel') ||
            title.contains('hotel') ||
            title.contains('khách sạn') ||
            title.contains('khach san'));
  }

  List<ItineraryActivityEntity> _visibleActivitiesForDay(
    ItineraryDayEntity day,
  ) {
    final items = day.activities
        .where((a) => a.latitude != null && a.longitude != null)
        .toList();
    if (day.dayNumber == 1) {
      return items.where((a) => !_isHotelStart(a)).toList();
    }
    return items;
  }

  List<ItineraryActivityEntity> _visibleCurrentDayActivities() {
    final items = widget.activities
        .where((a) => a.latitude != null && a.longitude != null)
        .toList();
    if (widget.selectedDay == 1) {
      return items.where((a) => !_isHotelStart(a)).toList();
    }
    return items;
  }

  List<mapbox.Point> _pointsFromActivities(
    List<ItineraryActivityEntity> activities,
  ) {
    return activities
        .map(
          (a) => mapbox.Point(
            coordinates: mapbox.Position(a.longitude!, a.latitude!),
          ),
        )
        .toList();
  }

  List<mapbox.Point> _currentItineraryPoints({bool includeUser = false}) {
    final points = <mapbox.Point>[];
    if (_showAllDays) {
      for (final day in widget.allDays) {
        points.addAll(_pointsFromActivities(_visibleActivitiesForDay(day)));
      }
    } else {
      points.addAll(_pointsFromActivities(_visibleCurrentDayActivities()));
    }
    if (includeUser && _userPosition != null) {
      points.add(mapbox.Point(coordinates: _userPosition!));
    }
    return points;
  }

  Future<void> _fitCameraToPoints(List<mapbox.Point> points) async {
    if (_mapboxMap == null || points.isEmpty) return;
    if (points.length == 1) {
      await _mapboxMap?.easeTo(
        mapbox.CameraOptions(center: points.first, zoom: 15.0),
        mapbox.MapAnimationOptions(duration: 800),
      );
      return;
    }

    final camera = await _mapboxMap?.cameraForCoordinates(
      points,
      mapbox.MbxEdgeInsets(top: 120, left: 64, bottom: 210, right: 64),
      null,
      null,
    );

    if (camera != null) {
      double zoom = camera.zoom ?? 13.5;
      if (zoom < 4.5) zoom = 4.5;
      await _mapboxMap?.easeTo(
        mapbox.CameraOptions(
          center: camera.center,
          zoom: zoom,
          padding: camera.padding,
        ),
        mapbox.MapAnimationOptions(duration: 800),
      );
    }
  }

  Future<void> _drawDayRoute(
    List<ItineraryActivityEntity> activities,
    Color color, {
    bool showArrows = true,
    double lineOpacity = 0.72,
    double lineWidth = 4.2,
  }) async {
    if (_polylineAnnotationManager == null || activities.length < 2) return;
    final routePositions = await _loadRoutePositions(activities);
    if (routePositions.length < 2) return;

    await _polylineAnnotationManager?.create(
      mapbox.PolylineAnnotationOptions(
        geometry: mapbox.LineString(coordinates: routePositions),
        lineColor: color.toARGB32(),
        lineWidth: lineWidth,
        lineOpacity: lineOpacity,
      ),
    );
    if (showArrows) {
      await _drawRouteArrows(routePositions, color);
    }
  }

  Future<List<mapbox.Position>> _loadRoutePositions(
    List<ItineraryActivityEntity> activities,
  ) async {
    final route = <mapbox.Position>[];

    for (var i = 0; i < activities.length - 1; i++) {
      final from = activities[i];
      final to = activities[i + 1];
      final key =
          '${from.id}:${from.longitude},${from.latitude}->${to.id}:${to.longitude},${to.latitude}';
      final segment = _routeCache[key] ??= await MapUtils.getGoongRoute([
        mapbox.Position(from.longitude!, from.latitude!),
        mapbox.Position(to.longitude!, to.latitude!),
      ]);

      if (route.isNotEmpty && segment.isNotEmpty) {
        route.addAll(segment.skip(1));
      } else {
        route.addAll(segment);
      }
    }

    return route;
  }

  Future<void> _drawRouteArrows(
    List<mapbox.Position> routePositions,
    Color color,
  ) async {
    if (_pointAnnotationManager == null || routePositions.length < 2) return;
    final icon = await _createRouteArrowIcon(color);
    final maxArrows = math.min(4, math.max(1, routePositions.length ~/ 18));
    final step = math.max(8, routePositions.length ~/ (maxArrows + 1));

    for (var i = step; i < routePositions.length - 1; i += step) {
      final from = routePositions[i - 1];
      final to = routePositions[i + 1];
      final point = mapbox.Point(coordinates: routePositions[i]);

      await _pointAnnotationManager?.create(
        mapbox.PointAnnotationOptions(
          geometry: point,
          image: icon,
          iconSize: 0.42,
          iconRotate: _bearingDegrees(from, to),
          iconAnchor: mapbox.IconAnchor.CENTER,
        ),
      );
    }
  }

  double _bearingDegrees(mapbox.Position from, mapbox.Position to) {
    final lat1 = _degToRad(from.lat.toDouble());
    final lat2 = _degToRad(to.lat.toDouble());
    final dLng = _degToRad((to.lng - from.lng).toDouble());
    final y = math.sin(dLng) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  double _degToRad(double value) => value * math.pi / 180;

  Future<void> _drawClusteredMarkers(List<_MapMarkerItem> items) async {
    if (_pointAnnotationManager == null || items.isEmpty) return;
    final buckets = <String, List<_MapMarkerItem>>{};
    for (final item in items) {
      final key = item.isSelectedDay
          ? 'selected:${item.activity.id}'
          : _clusterKey(item.activity);
      buckets.putIfAbsent(key, () => []).add(item);
    }

    for (final group in buckets.values) {
      if (group.length >= 3 && !group.any((item) => item.isSelectedDay)) {
        final avgLng =
            group
                .map((item) => item.activity.longitude!)
                .reduce((a, b) => a + b) /
            group.length;
        final avgLat =
            group
                .map((item) => item.activity.latitude!)
                .reduce((a, b) => a + b) /
            group.length;
        final icon = await _createClusterIcon(group.length, group.first.color);
        await _pointAnnotationManager?.create(
          mapbox.PointAnnotationOptions(
            geometry: mapbox.Point(
              coordinates: mapbox.Position(avgLng, avgLat),
            ),
            image: icon,
            iconSize: 0.74,
            iconAnchor: mapbox.IconAnchor.CENTER,
          ),
        );
        continue;
      }

      for (final item in group) {
        final point = mapbox.Point(
          coordinates: mapbox.Position(
            item.activity.longitude!,
            item.activity.latitude!,
          ),
        );
        final icon = item.isHotel
            ? await _createDayHotelIcon(item.dayNumber, item.color)
            : await _createDayStopIcon(
                item.dayNumber,
                item.stopNumber,
                item.color,
                _iconForActivity(item.activity),
                isCompleted: item.activity.status == ActivityStatus.daDi,
              );
        final annotation = await _pointAnnotationManager?.create(
          mapbox.PointAnnotationOptions(
            geometry: point,
            image: icon,
            iconSize: item.isSelectedDay ? 0.86 : 0.58,
            iconAnchor: mapbox.IconAnchor.CENTER,
          ),
        );
        if (annotation != null) {
          _annotationIdMap[annotation.id] = item.activity.id;
        }
      }
    }
  }

  String _clusterKey(ItineraryActivityEntity activity) {
    final lng = (activity.longitude! / 0.012).round();
    final lat = (activity.latitude! / 0.012).round();
    return '$lng:$lat';
  }

  @override
  bool onPointAnnotationClick(mapbox.PointAnnotation annotation) {
    final id = _annotationIdMap[annotation.id];
    if (id != null) widget.onMarkerTap?.call(id);
    return true;
  }

  void _onMapCreated(mapbox.MapboxMap map) {
    _mapboxMap = map;
    widget.onMapCreated?.call(map);
  }

  void _onStyleLoaded(mapbox.StyleLoadedEventData event) async {
    if (!mounted) return;
    _isStyleLoaded = true;
    _pointAnnotationManager = await _mapboxMap?.annotations
        .createPointAnnotationManager();
    _polylineAnnotationManager = await _mapboxMap?.annotations
        .createPolylineAnnotationManager();
    _pointAnnotationManager?.addOnPointAnnotationClickListener(this);
    _updateMapContent();
  }

  @override
  void didUpdateWidget(covariant ItineraryMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isStyleLoaded &&
        (widget.activities != oldWidget.activities ||
            widget.selectedDay != oldWidget.selectedDay ||
            widget.allDays != oldWidget.allDays)) {
      _updateMapContent();
    }
  }

  Future<void> _updateMapContent() async {
    if (_mapboxMap == null || _pointAnnotationManager == null) return;
    await _pointAnnotationManager?.deleteAll();
    await _polylineAnnotationManager?.deleteAll();
    _annotationIdMap.clear();

    final itineraryPoints = <mapbox.Point>[];
    if (_showAllDays) {
      final markerItems = <_MapMarkerItem>[];
      for (final day in widget.allDays) {
        final isSelectedDay = day.dayNumber == widget.selectedDay;
        final color = isSelectedDay
            ? kSelectedRouteColor
            : kDayColors[(day.dayNumber - 1) % kDayColors.length];
        final acts = _visibleActivitiesForDay(day);
        await _drawDayRoute(
          acts,
          color,
          showArrows: isSelectedDay,
          lineOpacity: isSelectedDay ? 0.58 : 0.18,
          lineWidth: isSelectedDay ? 3.2 : 2.1,
        );
        int stopNumber = 1;

        for (final activity in acts) {
          final isHotel = _isHotelStart(activity);
          markerItems.add(
            _MapMarkerItem(
              activity: activity,
              dayNumber: day.dayNumber,
              stopNumber: isHotel ? 0 : stopNumber++,
              color: color,
              isSelectedDay: isSelectedDay,
              isHotel: isHotel,
            ),
          );
          itineraryPoints.add(
            mapbox.Point(
              coordinates: mapbox.Position(
                activity.longitude!,
                activity.latitude!,
              ),
            ),
          );
        }
      }
      await _drawClusteredMarkers(markerItems);
    } else {
      final acts = _visibleCurrentDayActivities();
      await _drawDayRoute(
        acts,
        kSelectedRouteColor,
        lineOpacity: 0.62,
        lineWidth: 3.3,
      );
      int stopNumber = 1;

      for (final activity in acts) {
        final point = mapbox.Point(
          coordinates: mapbox.Position(activity.longitude!, activity.latitude!),
        );
        itineraryPoints.add(point);
        final isHotel = _isHotelStart(activity);
        final color = activity.status == ActivityStatus.daDi
            ? kDoneStopColor
            : kSelectedRouteColor;
        final icon = isHotel
            ? await _createHotelIcon()
            : await _createStopIcon(
                stopNumber++,
                color,
                _iconForActivity(activity),
                isCompleted: activity.status == ActivityStatus.daDi,
              );
        final annotation = await _pointAnnotationManager?.create(
          mapbox.PointAnnotationOptions(
            geometry: point,
            image: icon,
            iconSize: 0.9,
            iconAnchor: mapbox.IconAnchor.CENTER,
          ),
        );
        if (annotation != null) _annotationIdMap[annotation.id] = activity.id;
      }
    }

    if (_userPosition != null) {
      final icon = await _createCurrentLocationIcon();
      await _pointAnnotationManager?.create(
        mapbox.PointAnnotationOptions(
          geometry: mapbox.Point(coordinates: _userPosition!),
          image: icon,
          iconSize: 1.38,
          iconAnchor: mapbox.IconAnchor.CENTER,
        ),
      );
    }

    await _fitCameraToPoints(itineraryPoints);
  }

  @override
  Widget build(BuildContext context) {
    mapbox.Point center = mapbox.Point(
      coordinates: mapbox.Position(108.2235, 16.0544),
    );
    for (final activity in _visibleCurrentDayActivities()) {
      center = mapbox.Point(
        coordinates: mapbox.Position(activity.longitude!, activity.latitude!),
      );
      break;
    }

    return Stack(
      children: [
        mapbox.MapWidget(
          key: const ValueKey('itinerary_map'),
          onMapCreated: _onMapCreated,
          onStyleLoadedListener: _onStyleLoaded,
          styleUri: AppConfig.kGoongMapStyle,
          cameraOptions: mapbox.CameraOptions(center: center, zoom: 14),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height * 0.35,
          right: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(24),
                color: _showAllDays ? AppColors.primary : Colors.white,
                child: InkWell(
                  onTap: () {
                    setState(() => _showAllDays = !_showAllDays);
                    _updateMapContent();
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _showAllDays ? Icons.today : Icons.calendar_month,
                          size: 18,
                          color: _showAllDays
                              ? Colors.white
                              : AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _showAllDays
                              ? 'Ngày ${widget.selectedDay}'
                              : 'Tất cả',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _showAllDays
                                ? Colors.white
                                : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Material(
                elevation: 4,
                shape: const CircleBorder(),
                color: Colors.white,
                child: InkWell(
                  onTap: _focusOnUser,
                  customBorder: const CircleBorder(),
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(
                      Icons.my_location,
                      size: 22,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MapMarkerItem {
  final ItineraryActivityEntity activity;
  final int dayNumber;
  final int stopNumber;
  final Color color;
  final bool isSelectedDay;
  final bool isHotel;

  const _MapMarkerItem({
    required this.activity,
    required this.dayNumber,
    required this.stopNumber,
    required this.color,
    required this.isSelectedDay,
    required this.isHotel,
  });
}
