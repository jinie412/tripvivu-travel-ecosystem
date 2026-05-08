import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:travel_advisor_mobile/core/config/app_config.dart';
import 'package:travel_advisor_mobile/core/constants/app_colors.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_activity_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_day_entity.dart';
import 'package:travel_advisor_mobile/core/utils/map_utils.dart';

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
  mapbox.PolylineAnnotationManager? _polylineAnnotationManager;
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

      final lastPos = await geo.Geolocator.getLastKnownPosition();
      if (lastPos != null && mounted) {
        setState(() => _userPosition = mapbox.Position(lastPos.longitude, lastPos.latitude));
        if (_isStyleLoaded) _updateMapContent();
      }

      final pos = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(accuracy: geo.LocationAccuracy.high),
      );
      
      if (mounted) {
        setState(() => _userPosition = mapbox.Position(pos.longitude, pos.latitude));
        if (_isStyleLoaded) _updateMapContent();
      }
    } catch (e) {
      debugPrint("📍 Location error: $e");
    }
  }

  void _focusOnUser() {
    if (_userPosition != null && _mapboxMap != null) {
      _mapboxMap?.flyTo(
        mapbox.CameraOptions(
          center: mapbox.Point(coordinates: _userPosition!), 
          zoom: 15.0,
          bearing: 0,
          pitch: 0,
        ),
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
    if (id != null) {
      widget.onMarkerTap?.call(id);
      _handleMarkerTap(id);
    }
    return true;
  }

  void _handleMarkerTap(String activityId) async {
    if (_mapboxMap == null) return;
    
    // 1. Tìm vị trí của địa điểm hiện tại và địa điểm kế tiếp
    final acts = widget.activities.where((a) => a.latitude != null && a.longitude != null).toList();
    final currentIndex = acts.indexWhere((a) => a.id == activityId);
    if (currentIndex == -1) return;

    final currentAct = acts[currentIndex];
    final nextAct = (currentIndex < acts.length - 1) ? acts[currentIndex + 1] : null;

    // 2. Xóa các đường cũ
    await _polylineAnnotationManager?.deleteAll();
    
    List<mapbox.Point> zoomPoints = [];
    final currentPos = mapbox.Position(currentAct.longitude!, currentAct.latitude!);
    zoomPoints.add(mapbox.Point(coordinates: currentPos));

    // --- ĐƯỜNG 1: TỪ VỊ TRÍ NGƯỜI DÙNG -> ĐỊA ĐIỂM HIỆN TẠI ---
    if (_userPosition != null) {
      zoomPoints.add(mapbox.Point(coordinates: _userPosition!));
      
      // Gọi API Goong để lấy đường đi thực tế
      final routePoints = await MapUtils.getGoongRoute([_userPosition!, currentPos]);
      
      if (routePoints.length >= 2) {
        _polylineAnnotationManager?.create(mapbox.PolylineAnnotationOptions(
          geometry: mapbox.LineString(coordinates: routePoints),
          lineColor: Colors.blue.value,
          lineWidth: 5.0,
          lineOpacity: 0.8,
        ));
      }
    }

    // --- ĐƯỜNG 2: TỪ ĐỊA ĐIỂM HIỆN TẠI -> ĐỊA ĐIỂM KẾ TIẾP ---
    if (nextAct != null) {
      final nextPos = mapbox.Position(nextAct.longitude!, nextAct.latitude!);
      zoomPoints.add(mapbox.Point(coordinates: nextPos));

      // Gọi API Goong để lấy đường đi thực tế
      final routePoints = await MapUtils.getGoongRoute([currentPos, nextPos]);

      if (routePoints.length >= 2) {
        _polylineAnnotationManager?.create(mapbox.PolylineAnnotationOptions(
          geometry: mapbox.LineString(coordinates: routePoints),
          lineColor: Colors.orange.value,
          lineWidth: 4.0,
          lineOpacity: 0.7,
        ));
      }
    }

    // 3. Camera Focus (North-up & Padding)
    if (zoomPoints.isNotEmpty) {
      final camera = await _mapboxMap?.cameraForCoordinates(
        zoomPoints,
        mapbox.MbxEdgeInsets(top: 100, left: 100, bottom: 400, right: 100),
        0, 0
      );
      if (camera != null) {
        _mapboxMap?.flyTo(camera, mapbox.MapAnimationOptions(duration: 1000));
      }
    }
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
    
    _polylineAnnotationManager = await _mapboxMap?.annotations.createPolylineAnnotationManager();
    
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
    await _polylineAnnotationManager?.deleteAll();
    _annotationIdMap.clear();

    final List<mapbox.Point> itinPoints = [];
    if (_showAllDays) {
      for (final day in widget.allDays) {
        final color = kDayColors[(day.dayNumber - 1) % kDayColors.length];
        final acts = day.activities.where((a) => a.latitude != null && a.longitude != null).toList();
        for (int i = 0; i < acts.length; i++) {
          final p = mapbox.Point(coordinates: mapbox.Position(acts[i].longitude!, acts[i].latitude!));
          itinPoints.add(p);
          final icon = await _createDayNumberIcon(day.dayNumber, i, color);
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
        final icon = await _createNumberIcon(i + 1, color);
        final ann = await _pointAnnotationManager?.create(mapbox.PointAnnotationOptions(geometry: p, image: icon, iconSize: 1.0, iconAnchor: mapbox.IconAnchor.CENTER));
        if (ann != null) _annotationIdMap[ann.id] = acts[i].id;
      }
    }

    if (_userPosition != null) {
      final icon = await _createCurrentLocationIcon();
      await _pointAnnotationManager?.create(mapbox.PointAnnotationOptions(
        geometry: mapbox.Point(coordinates: _userPosition!),
        image: icon, 
        iconSize: 1.5,
        iconAnchor: mapbox.IconAnchor.CENTER,
      ));
    }

    final List<mapbox.Point> cameraPoints = List.from(itinPoints);
    if (_userPosition != null) cameraPoints.add(mapbox.Point(coordinates: _userPosition!));

    if (cameraPoints.isNotEmpty) {
      final camera = await _mapboxMap?.cameraForCoordinates(
        cameraPoints,
        mapbox.MbxEdgeInsets(top: 100, left: 60, bottom: 350, right: 60), 
        0, 0
      );

      if (camera != null) {
        double zoom = camera.zoom ?? 13.5;
        if (zoom < 4.5) zoom = 4.5;
        _mapboxMap?.flyTo(
          mapbox.CameraOptions(center: camera.center, zoom: zoom, padding: camera.padding, bearing: 0, pitch: 0),
          mapbox.MapAnimationOptions(duration: 1000)
        );
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
