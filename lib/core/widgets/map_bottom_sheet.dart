import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:travel_advisor_mobile/core/utils/map_utils.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:travel_advisor_mobile/core/config/app_config.dart';
import 'package:travel_advisor_mobile/core/constants/app_colors.dart';

class MapBottomSheet extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String name;
  final String address;

  static void show(
    BuildContext context, {
    required double latitude,
    required double longitude,
    required String name,
    required String address,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MapBottomSheet(
        latitude: latitude,
        longitude: longitude,
        name: name,
        address: address,
      ),
    );
  }

  const MapBottomSheet({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.name,
    required this.address,
  });

  /// Vẽ Marker Pin vị trí cực kỳ nổi bật
  Future<Uint8List> _createPlaceMarker() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = ui.Size(128, 128);

    // 1. Bóng đổ
    final shadowPaint = Paint()..color = Colors.black.withOpacity(0.2);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2 + 5), 45, shadowPaint);

    // 2. Vòng tròn trắng ngoài cùng
    final outerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 40, outerPaint);

    // 3. Vòng tròn đỏ bên trong
    final innerPaint = Paint()..color = const Color(0xFFF43F5E); // Màu đỏ hồng chủ đạo
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 32, innerPaint);

    // 4. Chấm trắng nhỏ ở tâm
    final dotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 12, dotPaint);

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return pngBytes!.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65, // Tăng nhẹ chiều cao
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        address,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.grey[100],
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: MapBottomSheetContent(
                  latitude: latitude,
                  longitude: longitude,
                  name: name,
                ),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => _openExternalMap(context),
                icon: const Icon(Icons.directions, color: Colors.white),
                label: const Text(
                  'Bắt đầu dẫn đường',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openExternalMap(BuildContext context) async {
    final Uri uri = Uri.parse(MapUtils.getDirectionUrl(latitude, longitude, name: name));
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('_openExternalMap failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở bản đồ')),
        );
      }
    }
  }
}

// Widget chuyên biệt cho Map trong BottomSheet để xử lý Marker
class MapBottomSheetContent extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String name;

  const MapBottomSheetContent({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.name,
  });

  @override
  State<MapBottomSheetContent> createState() => _MapBottomSheetContentState();
}

class _MapBottomSheetContentState extends State<MapBottomSheetContent> {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;

  Future<Uint8List> _createPlaceMarker() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = ui.Size(128, 128);
    final shadowPaint = Paint()..color = Colors.black.withOpacity(0.25);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2 + 5), 45, shadowPaint);
    final outerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 42, outerPaint);
    final innerPaint = Paint()..color = const Color(0xFF1A6EBD); // Màu Xanh dương hệ thống
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 34, innerPaint);
    final dotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 16, dotPaint); // Tăng từ 12 lên 16
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return pngBytes!.buffer.asUint8List();
  }

  void _onStyleLoaded(StyleLoadedEventData event) async {
    if (_mapboxMap == null) return;
    _pointAnnotationManager = await _mapboxMap!.annotations.createPointAnnotationManager();
    final iconBytes = await _createPlaceMarker();
    
    await _pointAnnotationManager!.create(
      PointAnnotationOptions(
        geometry: Point(coordinates: Position(widget.longitude, widget.latitude)),
        image: iconBytes,
        iconSize: 1.2, // Tăng từ 0.6 lên 1.2 (Gấp đôi)
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MapWidget(
      key: const ValueKey("bottom_sheet_map_widget"),
      styleUri: AppConfig.kGoongMapStyle,
      cameraOptions: CameraOptions(
        center: Point(coordinates: Position(widget.longitude, widget.latitude)),
        zoom: 16.0,
      ),
      onMapCreated: (map) => _mapboxMap = map,
      onStyleLoadedListener: _onStyleLoaded,
    );
  }
}
