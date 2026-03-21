import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/features/home/presentation/screens/see_all_screen.dart';
import 'package:travel_advisor_mobile/features/home/presentation/widgets/detailed_place_card.dart';
import '../cubit/itinerary_cubit.dart';
import '../cubit/itinerary_state.dart';
import '../../domain/entities/itinerary_detail_entity.dart';
import '../../domain/entities/itinerary_activity_entity.dart';
import '../widgets/day_selector_chip.dart';
import '../widgets/timeline_activity_card.dart';
import '../../../../core/di/injection_container.dart';
import '../../../place/presentation/screens/place_detail_screen.dart';
import '../../../place/presentation/cubit/place_detail_cubit.dart';
import '../../../food/presentation/screens/food_menu_screen.dart';
import '../../../food/presentation/widgets/pre_order_popup.dart';

class ItineraryDetailScreen extends StatefulWidget {
  final String itineraryId;
  final ItineraryDetailEntity? initialDetail;

  const ItineraryDetailScreen({
    super.key, 
    required this.itineraryId,
    this.initialDetail,
  });

  @override
  State<ItineraryDetailScreen> createState() => _ItineraryDetailScreenState();
}

class _ItineraryDetailScreenState extends State<ItineraryDetailScreen> {
  int _selectedDay = 1;
  bool _isPublic = true;
  GoogleMapController? _mapController;
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _activityKeys = {};

  void _showAddPlaceScreen() {
    void onAdd(String name) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm $name vào lịch trình thành công!'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context); // Go back to itinerary detail
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SeeAllScreen(
          title: 'Điểm đến nổi bật',
          items: [
            DetailedPlaceCard(
              title: 'Sapa',
              rating: 4.5,
              reviews: '1.2k',
              imageUrl: 'https://images.unsplash.com/photo-1503506046705-f6a745409929?w=800&q=80',
              placeholderColor: 0xFFE2E8F0,
              info: 'Việt Nam • Địa điểm du lịch',
              onTap: () {},
              onAddTap: () => onAdd('Sapa'),
            ),
            DetailedPlaceCard(
              title: 'Hội An',
              rating: 4.8,
              reviews: '2.5k',
              imageUrl: 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800&q=80',
              placeholderColor: 0xFFF1F5F9,
              info: 'Việt Nam • Phố cổ du lịch',
              onTap: () {},
              onAddTap: () => onAdd('Hội An'),
            ),
            DetailedPlaceCard(
              title: 'Đà Nẵng',
              rating: 4.7,
              reviews: '1.8k',
              imageUrl: 'https://images.unsplash.com/photo-1559592471-744e99c1586e?w=800&q=80',
              placeholderColor: 0xFFCBD5E1,
              info: 'Việt Nam • Thành phố biển',
              onTap: () {},
              onAddTap: () => onAdd('Đà Nẵng'),
            ),
          ],
        ),
      ),
    );
  }

  void _onDayChanged(int day) {
    setState(() => _selectedDay = day);
    // Reset camera or update markers logic will be handled in build
  }

  void _scrollToActivity(String activityId) {
    final key = _activityKeys[activityId];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 500),
        alignment: 0.1,
      );
    }
  }

  void _zoomToActivity(ItineraryActivityEntity activity) {
    // 1. Zoom map if available
    if (activity.latitude != null && activity.longitude != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(activity.latitude!, activity.longitude!),
          15,
        ),
      );
    }
    
    // 2. Navigate to Place Detail
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => sl<PlaceDetailCubit>(),
          child: PlaceDetailScreen(
            placeId: activity.id,
            showRelatedPlaces: false,
          ),
        ),
      ),
    );
  }

  void _showShareSheet() {
    final invitedUsers = <String>{};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 24),
                const Text('Chia sẻ lịch trình', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Mời bạn bè cùng tham gia và chỉnh sửa lịch trình chung cho chuyến đi này.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 24),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm qua tên hoặc email...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView(
                    children: [
                       _shareUserItem('Nguyễn Văn A', 'anv@example.com', 'https://i.pravatar.cc/150?u=a', invitedUsers.contains('a'), () {
                         setModalState(() => invitedUsers.add('a'));
                       }),
                       _shareUserItem('Trần Thị B', 'btt@example.com', 'https://i.pravatar.cc/150?u=b', invitedUsers.contains('b'), () {
                         setModalState(() => invitedUsers.add('b'));
                       }),
                       _shareUserItem('Lê Văn C', 'clv@example.com', 'https://i.pravatar.cc/150?u=c', invitedUsers.contains('c'), () {
                         setModalState(() => invitedUsers.add('c'));
                       }),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _shareUserItem(String name, String email, String avatar, bool isInvited, VoidCallback onInvite) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(backgroundImage: NetworkImage(avatar)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(email, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: isInvited ? null : onInvite,
            style: ElevatedButton.styleFrom(
              backgroundColor: isInvited ? Colors.grey.shade300 : AppColors.primary,
              foregroundColor: isInvited ? Colors.grey : Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: Text(isInvited ? 'Đã gửi' : 'Gửi lời mời', style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _showPreOrderDemo() {
    const restaurantName = 'Cơm tấm Ba Ghiền';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PreOrderPopup(
        restaurantName: restaurantName,
        onOrderTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FoodMenuScreen(restaurantName: restaurantName)),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _ItineraryDetailView(
        selectedDay: _selectedDay,
        isPublic: _isPublic,
        onDayChanged: _onDayChanged,
        onPublicChanged: (v) => setState(() => _isPublic = v),
        onAddPlaceTap: _showAddPlaceScreen,
        mapController: _mapController,
        onMapCreated: (controller) => _mapController = controller,
        scrollController: _scrollController,
        activityKeys: _activityKeys,
        onActivityTap: _zoomToActivity,
        onShareTap: _showShareSheet,
        onMarkerTap: (id) {
          // Find activity by id and scroll to it
          _scrollToActivity(id);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showPreOrderDemo,
        label: const Text('Demo Đặt món'),
        icon: const Icon(Icons.restaurant),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}

class _ItineraryDetailView extends StatelessWidget {
  final int selectedDay;
  final bool isPublic;
  final Function(int) onDayChanged;
  final Function(bool) onPublicChanged;
  final VoidCallback onAddPlaceTap;
  final GoogleMapController? mapController;
  final Function(GoogleMapController) onMapCreated;
  final ScrollController scrollController;
  final Map<String, GlobalKey> activityKeys;
  final Function(ItineraryActivityEntity) onActivityTap;
  final VoidCallback onShareTap;
  final Function(String) onMarkerTap;

  const _ItineraryDetailView({
    required this.selectedDay,
    required this.isPublic,
    required this.onDayChanged,
    required this.onPublicChanged,
    required this.onAddPlaceTap,
    this.mapController,
    required this.onMapCreated,
    required this.scrollController,
    required this.activityKeys,
    required this.onActivityTap,
    required this.onShareTap,
    required this.onMarkerTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<ItineraryCubit, ItineraryState>(
        builder: (context, state) {
          if (state is ItineraryLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ItineraryError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<ItineraryCubit>().loadData(),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is ItineraryLoaded && state.selectedItinerary != null) {
            final itin = state.selectedItinerary!;
            final currentDayData = itin.days.firstWhere(
              (d) => d.dayNumber == selectedDay, 
              orElse: () => itin.days.isNotEmpty ? itin.days.first : throw Exception('No days data'),
            );

            // Create markers
            // final markers = _buildMarkers(currentDayData.activities);

            return Stack(
              children: [
                // 1. Google Map at the top
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 350,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                      ),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map_outlined, size: 64, color: Colors.white70),
                          SizedBox(height: 12),
                          Text(
                            'Map is temporarily disabled',
                            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // child: GoogleMap(
                  //   initialCameraPosition: CameraPosition(
                  //     target: markers.isNotEmpty 
                  //       ? markers.first.position 
                  //       : const LatLng(10.7769, 106.7009),
                  //     zoom: 14,
                  //   ),
                  //   markers: markers,
                  //   onMapCreated: (controller) {
                  //     onMapCreated(controller);
                  //     _fitBounds(controller, markers);
                  //   },
                  //   zoomControlsEnabled: false,
                  //   mapToolbarEnabled: false,
                  //   myLocationButtonEnabled: false,
                  // ),
                ),
                
                // 2. Main Content (Scrollable list)
                SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    children: [
                      const SizedBox(height: 280),
                      _buildContentCard(context, itin, currentDayData),
                    ],
                  ),
                ),
                
                // 3. AppBar Buttons
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 20,
                  right: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _floatingCircleButton(Icons.arrow_back_ios_new, () => Navigator.pop(context)),
                      _floatingCircleButton(Icons.share_outlined, onShareTap),
                    ],
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  // Set<Marker> _buildMarkers(List<ItineraryActivityEntity> activities) {
  //   return activities
  //       .where((a) => a.latitude != null && a.longitude != null)
  //       .map((a) {
  //     return Marker(
  //       markerId: MarkerId(a.id),
  //       position: LatLng(a.latitude!, a.longitude!),
  //       infoWindow: InfoWindow(title: a.title, snippet: a.locationName),
  //       icon: _getMarkerIcon(a.status),
  //       onTap: () => onMarkerTap(a.id),
  //     );
  //   }).toSet();
  // }

  // BitmapDescriptor _getMarkerIcon(ActivityStatus status) {
  //   // Ideally use custom marker images, but for now we'll use default colors
  //   switch (status) {
  //     case ActivityStatus.daDi:
  //       return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
  //     case ActivityStatus.dangDi:
  //       return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
  //     case ActivityStatus.diQua:
  //       return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
  //     case ActivityStatus.chuaDi:
  //       return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
  //   }
  // }

  // void _fitBounds(GoogleMapController controller, Set<Marker> markers) {
  //   if (markers.isEmpty) return;
  //   
  //   double? minLat, maxLat, minLng, maxLng;
  //   for (final marker in markers) {
  //     final lat = marker.position.latitude;
  //     final lng = marker.position.longitude;
  //     if (minLat == null || lat < minLat) minLat = lat;
  //     if (maxLat == null || lat > maxLat) maxLat = lat;
  //     if (minLng == null || lng < minLng) minLng = lng;
  //     if (maxLng == null || lng > maxLng) maxLng = lng;
  //   }

  //   controller.animateCamera(
  //     CameraUpdate.newLatLngBounds(
  //       LatLngBounds(
  //         southwest: LatLng(minLat!, minLng!),
  //         northeast: LatLng(maxLat!, maxLng!),
  //       ),
  //       50.0,
  //     ),
  //   );
  // }

  Widget _buildContentCard(BuildContext context, ItineraryDetailEntity itin, dynamic currentDayData) {
    final currencyFormatter = NumberFormat('#,###', 'vi_VN');

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _statusBadge(itin.status),
              const Spacer(),
              Row(
                children: [
                  const Text('CÔNG KHAI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
                  const SizedBox(width: 4),
                  Transform.scale(
                    scale: 0.7,
                    child: Switch(
                      value: isPublic, 
                      onChanged: onPublicChanged, 
                      activeThumbColor: AppColors.primary,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            itin.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_month_outlined, size: 14, color: Color(0xFF6B7280)),
              const SizedBox(width: 6),
              Text(
                '${DateFormat('dd/MM').format(itin.startDate)} - ${DateFormat('dd/MM').format(itin.endDate)}, ${itin.startDate.year}',
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          // Stats summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _metaItem('Ngân sách', '${currencyFormatter.format(itin.estimatedBudget)} đ'),
              _metaItem('Thời gian', '${itin.durationDays} ngày'),
              _metaItem('Địa điểm', '${itin.activitiesCount} điểm'),
            ],
          ),
          
          const SizedBox(height: 32),
          // Day selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: itin.days.map<Widget>((day) => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: DaySelectorChip(
                  dayNumber: day.dayNumber,
                  locationCount: day.locationsCount,
                  isSelected: selectedDay == day.dayNumber,
                  onTap: () => onDayChanged(day.dayNumber),
                ),
              )).toList(),
            ),
          ),
          
          const SizedBox(height: 24),
          // Day details container
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: _dayMetaItem(Icons.sunny, '${currentDayData.temperature}°C', const Color(0xFFF59E0B))),
                    const SizedBox(width: 12),
                    Expanded(child: _dayMetaItem(Icons.access_time, currentDayData.totalDuration, const Color(0xFF3B82F6))),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${currentDayData.locationsCount} Địa điểm tham quan',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'DT: ${currencyFormatter.format(currentDayData.dayBudget)} đ',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          const Text(
            'Lịch chi tiết',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ...currentDayData.activities.asMap().entries.map((entry) {
            final activity = entry.value;
            // Create a key for this activity if it doesn't exist
            final key = activityKeys.putIfAbsent(activity.id, () => GlobalKey());
            
            return GestureDetector(
              key: key,
              onTap: () => onActivityTap(activity),
              child: TimelineActivityCard(
                activity: activity,
                isFirst: entry.key == 0,
                isLast: entry.key == currentDayData.activities.length - 1,
                onAddTap: onAddPlaceTap,
              ),
            );
          }),
          
          const SizedBox(height: 24),
          Center(
            child: OutlinedButton.icon(
              onPressed: onAddPlaceTap,
              icon: const Icon(Icons.add_location_alt_outlined, size: 18),
              label: const Text('THÊM ĐỊA ĐIỂM'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6B7280),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
      ),
    );
  }

  Widget _metaItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
      ],
    );
  }

  Widget _dayMetaItem(IconData icon, String value, Color iconColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Flexible(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF475569)), overflow: TextOverflow.ellipsis, maxLines: 1)),
      ],
    );
  }

  Widget _floatingCircleButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Icon(icon, size: 22, color: const Color(0xFF1E293B)),
      ),
    );
  }
}
