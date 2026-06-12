import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:travel_advisor_mobile/core/config/app_config.dart';
import 'package:travel_advisor_mobile/core/constants/app_colors.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_activity_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_day_entity.dart';

const List<Color> kDayColors = [
  Color(0xFF1A6EBD), Color(0xFFE67E22), Color(0xFF9B59B6), Color(0xFFE74C3C),
  Color(0xFF1ABC9C), Color(0xFFF39C12), Color(0xFF2C3E50),
];

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

class _ItineraryMapViewState extends State<ItineraryMapView> implements mapbox.OnPointAnnotationClickListener {
  mapbox.MapboxMap? _mapboxMap;
  mapbox.PointAnnotationManager? _pointAnnotationManager;
  bool _isStyleLoaded = false;
  bool _showAllDays = false;
  mapbox.Position? _userPosition; 
  final Map<String, String> _annotationIdMap = {};

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
        if (req == geo.LocationPermission.denied || req == geo.LocationPermission.deniedForever) {
          debugPrint("📍 Permission denied");
          return;
        }
      }

      // 1. Lấy vị trí gần nhất để marker hiện nhanh
      final lastPos = await geo.Geolocator.getLastKnownPosition();
      if (lastPos != null && mounted) {
        setState(() => _userPosition = mapbox.Position(lastPos.longitude, lastPos.latitude));
        if (_isStyleLoaded) _updateMapContent();
      }

      // 2. Lấy vị trí chính xác
      final pos = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(accuracy: geo.LocationAccuracy.high),
      );
      
      if (mounted) {
        setState(() => _userPosition = mapbox.Position(pos.longitude, pos.latitude));
        debugPrint("📍 Location found: ${pos.latitude}, ${pos.longitude}");
        
        // Hiện thông báo để người dùng biết đã lấy được vị trí
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📍 Đã xác định được vị trí: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );

        if (_isStyleLoaded) _updateMapContent();
      }
    } catch (e) {
      debugPrint("📍 Location error: $e");
    }
  }

  void _focusOnUser() {
    if (_userPosition != null && _mapboxMap != null) {
      _mapboxMap?.flyTo(
        mapbox.CameraOptions(center: mapbox.Point(coordinates: _userPosition!), zoom: 15.0),
        mapbox.MapAnimationOptions(duration: 1000),
      );
    } else {
      _getCurrentLocation();
    }
  }

  Future<Uint8List> _createNumberIcon(int number, Color bgColor) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = ui.Size(128, 128);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2 + 4), 52, Paint()..color = Colors.black.withOpacity(0.3));
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 48, Paint()..color = bgColor);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 48, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 6);
    final tp = TextPainter(text: TextSpan(text: number.toString(), style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr);
    tp.layout(); tp.paint(canvas, Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2));
    final img = await recorder.endRecording().toImage(128, 128);
    return (await img.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }

  Future<Uint8List> _createHotelIcon() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = ui.Size(128, 128);
    final center = Offset(size.width / 2, size.height / 2);

    canvas.drawCircle(center.translate(0, 5), 54, Paint()..color = Colors.black.withOpacity(0.25));
    canvas.drawCircle(center, 50, Paint()..color = const Color(0xFF0F766E));
    canvas.drawCircle(center, 50, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 6);

    const icon = Icons.hotel_rounded;
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: Colors.white,
          fontSize: 52,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2));
    final img = await recorder.endRecording().toImage(128, 128);
    return (await img.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }

  Future<Uint8List> _createDayNumberIcon(int day, int idx, Color color) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawCircle(const Offset(64, 67), 50, Paint()..color = Colors.black.withOpacity(0.25));
    canvas.drawCircle(const Offset(64, 64), 46, Paint()..color = color);
    canvas.drawCircle(const Offset(64, 64), 46, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 5);
    final tp = TextPainter(text: TextSpan(text: 'D$day.${idx + 1}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr);
    tp.layout(); tp.paint(canvas, Offset((128 - tp.width) / 2, (128 - tp.height) / 2));
    final img = await recorder.endRecording().toImage(128, 128);
    return (await img.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }

  Future<Uint8List> _createDayHotelIcon(int day, Color color) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawCircle(const Offset(64, 67), 50, Paint()..color = Colors.black.withOpacity(0.25));
    canvas.drawCircle(const Offset(64, 64), 46, Paint()..color = const Color(0xFF0F766E));
    canvas.drawCircle(const Offset(64, 64), 46, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 5);
    const icon = Icons.hotel_rounded;
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: Colors.white,
          fontSize: 40,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout(); tp.paint(canvas, Offset((128 - tp.width) / 2, (128 - tp.height) / 2));
    final label = TextPainter(text: TextSpan(text: 'D$day', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr);
    label.layout(); label.paint(canvas, Offset((128 - label.width) / 2, 88));
    final img = await recorder.endRecording().toImage(128, 128);
    return (await img.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }

  bool _isHotelStart(ItineraryActivityEntity activity) {
    final category = (activity.category ?? '').toLowerCase();
    final title = activity.title.toLowerCase();
    final sameTime = activity.startTime == activity.endTime;
    return sameTime && (category.contains('lưu trú') ||
        category.contains('khách sạn') ||
        category.contains('hotel') ||
        title.contains('hotel') ||
        title.contains('khách sạn'));
  }

  Future<Uint8List> _createCurrentLocationIcon() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawCircle(const Offset(64, 64), 48, Paint()..color = const Color(0xFF1A6EBD).withOpacity(0.2));
    canvas.drawCircle(const Offset(64, 64), 24, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(64, 64), 18, Paint()..color = const Color(0xFF1A6EBD));
    final img = await recorder.endRecording().toImage(128, 128);
    return (await img.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
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
    
    _pointAnnotationManager = await _mapboxMap?.annotations.createPointAnnotationManager();
    _pointAnnotationManager?.addOnPointAnnotationClickListener(this);
    _updateMapContent();
  }

  @override
  void didUpdateWidget(covariant ItineraryMapView old) {
    super.didUpdateWidget(old);
    if (_isStyleLoaded && (widget.activities != old.activities || widget.selectedDay != old.selectedDay)) _updateMapContent();
  }

  Future<void> _updateMapContent() async {
    if (_mapboxMap == null || _pointAnnotationManager == null) return;
    await _pointAnnotationManager?.deleteAll();
    _annotationIdMap.clear();

    final List<mapbox.Point> itinPoints = [];
    if (_showAllDays) {
      for (final day in widget.allDays) {
        final color = kDayColors[(day.dayNumber - 1) % kDayColors.length];
        final acts = day.activities.where((a) => a.latitude != null && a.longitude != null).toList();
        for (int i = 0; i < acts.length; i++) {
          final p = mapbox.Point(coordinates: mapbox.Position(acts[i].longitude!, acts[i].latitude!));
          itinPoints.add(p);
          final icon = _isHotelStart(acts[i])
              ? await _createDayHotelIcon(day.dayNumber, color)
              : await _createDayNumberIcon(day.dayNumber, i, color);
          final ann = await _pointAnnotationManager?.create(mapbox.PointAnnotationOptions(geometry: p, image: icon, iconSize: 1.0, iconAnchor: mapbox.IconAnchor.CENTER));
          if (ann != null) _annotationIdMap[ann.id] = acts[i].id;
        }
      }
    } else {
      final acts = widget.activities.where((a) => a.latitude != null && a.longitude != null).toList();
      for (int i = 0; i < acts.length; i++) {
        final p = mapbox.Point(coordinates: mapbox.Position(acts[i].longitude!, acts[i].latitude!));
        itinPoints.add(p);
        final color = acts[i].status == ActivityStatus.daDi ? const Color(0xFF10B981) : const Color(0xFF1A6EBD);
        final icon = _isHotelStart(acts[i])
            ? await _createHotelIcon()
            : await _createNumberIcon(i + 1, color);
        final ann = await _pointAnnotationManager?.create(mapbox.PointAnnotationOptions(geometry: p, image: icon, iconSize: 1.0, iconAnchor: mapbox.IconAnchor.CENTER));
        if (ann != null) _annotationIdMap[ann.id] = acts[i].id;
      }
    }

    // 📍 1. VẼ VỊ TRÍ NGƯỜI DÙNG (Vẽ cuối cùng để đè lên trên)
    if (_userPosition != null) {
      debugPrint("📍 Đang vẽ marker vị trí tại: ${_userPosition!.lat}, ${_userPosition!.lng}");
      final icon = await _createCurrentLocationIcon();
      await _pointAnnotationManager?.create(mapbox.PointAnnotationOptions(
        geometry: mapbox.Point(coordinates: _userPosition!),
        image: icon, 
        iconSize: 1.5, // Phóng to lên để dễ nhìn
        iconAnchor: mapbox.IconAnchor.CENTER,
      ));
    }

    // 🎯 CAMERA LOGIC
    final List<mapbox.Point> cameraPoints = List.from(itinPoints);
    if (_userPosition != null) {
      cameraPoints.add(mapbox.Point(coordinates: _userPosition!));
    }

    if (cameraPoints.isNotEmpty) {
      if (cameraPoints.length == 1) {
        _mapboxMap?.easeTo(mapbox.CameraOptions(center: cameraPoints.first, zoom: 15.0), mapbox.MapAnimationOptions(duration: 1000));
      } else {
        final camera = await _mapboxMap?.cameraForCoordinates(
          cameraPoints,
          mapbox.MbxEdgeInsets(top: 120, left: 60, bottom: 220, right: 60), 
          null, null
        );

        if (camera != null) {
          double zoom = camera.zoom ?? 13.5;
          if (zoom < 4.5) zoom = 4.5;
          _mapboxMap?.easeTo(mapbox.CameraOptions(center: camera.center, zoom: zoom, padding: camera.padding), mapbox.MapAnimationOptions(duration: 1000));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    mapbox.Point center = mapbox.Point(coordinates: mapbox.Position(108.2235, 16.0544));
    for (var a in widget.activities) {
      if (a.longitude != null && a.latitude != null) {
        center = mapbox.Point(coordinates: mapbox.Position(a.longitude!, a.latitude!)); break;
      }
    }

    return Stack(
      children: [
        mapbox.MapWidget(
          key: const ValueKey("itinerary_map"),
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
                elevation: 4, borderRadius: BorderRadius.circular(24),
                color: _showAllDays ? AppColors.primary : Colors.white,
                child: InkWell(
                  onTap: () { setState(() => _showAllDays = !_showAllDays); _updateMapContent(); },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(_showAllDays ? Icons.today : Icons.calendar_month, size: 18, color: _showAllDays ? Colors.white : AppColors.primary), const SizedBox(width: 6), Text(_showAllDays ? 'Ngày ${widget.selectedDay}' : 'Tất cả', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _showAllDays ? Colors.white : AppColors.primary))])),
                ),
              ),
              const SizedBox(height: 12),
              Material(
                elevation: 4, shape: const CircleBorder(), color: Colors.white,
                child: InkWell(onTap: _focusOnUser, customBorder: const CircleBorder(), child: Container(width: 44, height: 44, child: const Icon(Icons.my_location, size: 22, color: Color(0xFF1A6EBD)))),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
