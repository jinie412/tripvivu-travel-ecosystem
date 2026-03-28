import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import 'package:travel_advisor_mobile/features/home/presentation/screens/see_all_screen.dart';
import 'package:travel_advisor_mobile/features/home/presentation/widgets/detailed_place_card.dart';
import '../cubit/itinerary_cubit.dart';
import '../cubit/itinerary_state.dart';
import '../../domain/entities/itinerary_detail_entity.dart';
import '../../domain/entities/itinerary_activity_entity.dart';
import '../../domain/entities/itinerary_day_entity.dart';
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
          backgroundColor: AppColorsExt.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r12)),
        ),
      );
      Navigator.pop(context);
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
              placeholderColor: AppColorsExt.placeholder.value,
              info: 'Việt Nam • Địa điểm du lịch',
              onTap: () {},
              onAddTap: () => onAdd('Sapa'),
            ),
            DetailedPlaceCard(
              title: 'Hội An',
              rating: 4.8,
              reviews: '2.5k',
              imageUrl: 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800&q=80',
              placeholderColor: AppColorsExt.searchBarBg.value,
              info: 'Việt Nam • Phố cổ du lịch',
              onTap: () {},
              onAddTap: () => onAdd('Hội An'),
            ),
            DetailedPlaceCard(
              title: 'Đà Nẵng',
              rating: 4.7,
              reviews: '1.8k',
              imageUrl: 'https://images.unsplash.com/photo-1559592471-744e99c1586e?w=800&q=80',
              placeholderColor: AppColorsExt.divider.value,
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
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.r32)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.s24, vertical: AppSizes.s16),
            child: Column(
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColorsExt.divider, borderRadius: BorderRadius.circular(AppSizes.s2))),
                const SizedBox(height: AppSizes.s24),
                const Text('Chia sẻ lịch trình', style: AppTextStyles.heading2),
                const SizedBox(height: AppSizes.s8),
                Text('Mời bạn bè cùng tham gia và chỉnh sửa lịch trình chung cho chuyến đi này.', textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: AppSizes.s24),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm qua tên hoặc email...',
                    prefixIcon: const Icon(Icons.search, size: AppSizes.iconMd),
                    filled: true,
                    fillColor: AppColorsExt.searchBarBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.r16), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: AppSizes.s16),
                  ),
                ),
                const SizedBox(height: AppSizes.s24),
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
          CircleAvatar(backgroundImage: NetworkImage(avatar), radius: AppSizes.iconMd),
          const SizedBox(width: AppSizes.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
                Text(email, style: AppTextStylesExt.bodySmall.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: isInvited ? null : onInvite,
            style: ElevatedButton.styleFrom(
              backgroundColor: isInvited ? AppColorsExt.divider : AppColors.primary,
              foregroundColor: isInvited ? AppColors.textSecondary : AppColors.surface,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r12)),
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.s16),
            ),
            child: Text(isInvited ? 'Đã gửi' : 'Gửi lời mời', style: AppTextStylesExt.bodySmall.copyWith(fontWeight: FontWeight.bold)),
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
      backgroundColor: AppColors.surface,
      body: BlocBuilder<ItineraryCubit, ItineraryState>(
        builder: (context, state) {
          if (state is ItineraryLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ItineraryError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.s24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: AppSizes.s48, color: AppColorsExt.error),
                    const SizedBox(height: AppSizes.s16),
                    Text(state.message, textAlign: TextAlign.center, style: AppTextStyles.body),
                    const SizedBox(height: AppSizes.s16),
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
            
            // --- MOCK LOGIC for Day 2 and Day 3 ---
            final List<ItineraryDayEntity> displayDays = List.from(itin.days);
            if (displayDays.length < 3) {
              final firstDayDate = displayDays.isNotEmpty ? displayDays.first.date : DateTime.now();
              for (int i = displayDays.length + 1; i <= 3; i++) {
                displayDays.add(ItineraryDayEntity(
                  dayNumber: i,
                  date: firstDayDate.add(Duration(days: i - 1)),
                  temperature: 28 + i,
                  totalDuration: '7 giờ 45 phút',
                  locationsCount: 3,
                  dayBudget: 450000.0 * i,
                  activities: displayDays.first.activities, // Copy activities for visual mock
                ));
              }
            }

            final currentDayData = displayDays.firstWhere(
              (d) => d.dayNumber == selectedDay, 
              orElse: () => displayDays.first,
            );
            // --------------------------------------

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
                        colors: [AppColors.primary, AppColorsExt.profileBlue],
                      ),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map_outlined, size: AppSizes.s64, color: Colors.white70),
                          SizedBox(height: AppSizes.s12),
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
                      const SizedBox(height: 280), // Keep map overlap height
                      _buildContentCard(context, itin, currentDayData, displayDays),
                    ],
                  ),
                ),
                
                // 3. AppBar Buttons
                Positioned(
                  top: MediaQuery.of(context).padding.top + AppSizes.s12,
                  left: AppSizes.s20,
                  right: AppSizes.s20,
                  child: Row(
                    children: [
                      _floatingCircleButton(Icons.arrow_back_ios_new, () => Navigator.pop(context)),
                      const SizedBox(width: AppSizes.s16),
                      Expanded(
                        child: Text(
                          itin.title,
                          style: AppTextStyles.body.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: AppSizes.s16),
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

  Widget _buildContentCard(
    BuildContext context, 
    ItineraryDetailEntity itin, 
    ItineraryDayEntity currentDayData,
    List<ItineraryDayEntity> displayDays,
  ) {

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.r32)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.s20, vertical: AppSizes.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          const SizedBox(height: AppSizes.s12),
          // Day selector
          Align(
            alignment: Alignment.center,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
              children: displayDays.map<Widget>((day) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: DaySelectorChip(
                    dayNumber: day.dayNumber,
                    locationCount: day.locationsCount,
                    isSelected: selectedDay == day.dayNumber,
                    onTap: () => onDayChanged(day.dayNumber),
                  ),
                )).toList(),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.s12),
          Text(
            '${currentDayData.locationsCount} điểm tham quan du lịch',
            style: AppTextStylesExt.bodySmall.copyWith(
              color: const Color(0xFF94A3B8), // Gray color from image
              fontSize: 13,
            ),
          ),
          const SizedBox(height: AppSizes.s16),
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
          
          const SizedBox(height: AppSizes.s24),
          Center(
            child: OutlinedButton.icon(
              onPressed: onAddPlaceTap,
              icon: const Icon(Icons.add_location_alt_outlined, size: AppSizes.iconSm),
              label: const Text('THÊM ĐỊA ĐIỂM'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColorsExt.divider),
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.s24, vertical: AppSizes.s12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r12)),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.s64),
        ],
      ),
    );
  }



  Widget _floatingCircleButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, // Smaller size
        height: 32,
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(120),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}
