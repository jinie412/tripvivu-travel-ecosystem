import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';


import 'activity_edit_screen.dart';

import 'package:travel_advisor_mobile/core/constants/app_colors.dart';
import 'package:travel_advisor_mobile/core/constants/app_sizes.dart';
import 'package:travel_advisor_mobile/core/constants/app_text_styles.dart';
import 'package:travel_advisor_mobile/core/di/injection_container.dart';
import 'package:travel_advisor_mobile/core/utils/demo_review_store.dart';
import 'package:travel_advisor_mobile/features/food/presentation/screens/food_menu_screen.dart';
import 'package:travel_advisor_mobile/features/food/presentation/widgets/pre_order_popup.dart';
import 'package:travel_advisor_mobile/features/home/presentation/screens/see_all_screen.dart';
import 'package:travel_advisor_mobile/features/home/presentation/widgets/detailed_place_card.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_activity_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_day_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_detail_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/cubit/itinerary_cubit.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/cubit/itinerary_state.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/widgets/day_selector_chip.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/widgets/itinerary_review_dialog.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/widgets/timeline_activity_card.dart';
import 'package:travel_advisor_mobile/features/place/presentation/cubit/place_detail_cubit.dart';
import 'package:travel_advisor_mobile/features/place/presentation/screens/place_detail_screen.dart';
import 'package:travel_advisor_mobile/features/review/presentation/screens/rate_itinerary_screen.dart';
import '../widgets/itinerary_map_view.dart';


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
  MapboxMap? _mapController;
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _activityKeys = {};
  String? _highlightedActivityId;

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
      if (mounted) Navigator.pop(context);
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
  }

  void _scrollToActivity(String activityId) {
    setState(() => _highlightedActivityId = activityId);
    
    // Tìm activity để lấy tọa độ và zoom nhẹ
    final itin = (context.read<ItineraryCubit>().state as ItineraryLoaded).selectedItinerary;
    final activity = itin?.days.expand((d) => d.activities).firstWhere((a) => a.id == activityId);
    if (activity != null && activity.latitude != null && activity.longitude != null) {
      _mapController?.setCamera(
        CameraOptions(
          center: Point(coordinates: Position(activity.longitude!, activity.latitude!)),
          zoom: 15,
        ),
      );
      // Mapbox v0.4.4 doesn't have showMarkerInfoWindow, we'd need a custom popup
    }

    final key = _activityKeys[activityId];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 500),
        alignment: 0.1,
      );
    }

    // Reset highlight after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _highlightedActivityId = null);
      }
    });
  }

  void _zoomToActivity(ItineraryActivityEntity activity) {
    if (activity.latitude != null && activity.longitude != null) {
      _mapController?.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(activity.longitude!, activity.latitude!)),
          zoom: 17,
        ),
        MapAnimationOptions(duration: 1000),
      );
    }
  }

  void _navigateToPlaceDetail(ItineraryActivityEntity activity) {
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

  void _onEditActivity(ItineraryActivityEntity activity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActivityEditScreen(activity: activity),
      ),
    );
  }

  void _onEditTime(ItineraryActivityEntity activity, bool isStart) async {
    final initialTimeStr = isStart ? activity.startTime : activity.endTime;
    final parts = initialTimeStr.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColorsExt.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null && mounted) {
      final newTime = '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
      context.read<ItineraryCubit>().updateActivityTime(
            activity.id,
            startTime: isStart ? newTime : null,
            endTime: isStart ? null : newTime,
          );
    }
  }

  void _onReplaceActivity(ItineraryActivityEntity activity) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Tính năng thay thế địa điểm đang được phát triển!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r12)),
      ),
    );
  }

  void _onRateActivity(ItineraryActivityEntity activity) {
    double currentRating = DemoReviewStore.getLocationRating(activity.id) ?? 0;
    final TextEditingController commentController = TextEditingController(text: DemoReviewStore.userComments[activity.id] ?? '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Đánh giá ${activity.title}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Bạn cảm thấy địa điểm này thế nào?', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < currentRating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: const Color(0xFFFFC107),
                      size: 32,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        currentRating = index + 1.0;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Nhập cảm nhận của bạn...',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (currentRating > 0) {
                  DemoReviewStore.saveLocationRating(activity.id, currentRating, comment: commentController.text);
                  Navigator.pop(context);
                  // Refresh UI
                  setState(() {}); 
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã lưu đánh giá địa điểm!'),
                      backgroundColor: Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Lưu', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _onDeleteActivity(ItineraryActivityEntity activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa địa điểm'),
        content: Text('Bạn có chắc chắn muốn xóa "${activity.title}" khỏi lịch trình không?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã xóa ${activity.title}'),
                  backgroundColor: AppColorsExt.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Xóa', style: TextStyle(color: AppColorsExt.error, fontWeight: FontWeight.bold)),
          ),
        ],
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
                Text('Chia sẻ lịch trình', style: AppTextStyles.heading2),
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
    const placeId = 'demo-place';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PreOrderPopup(
        title: 'Gợi ý cho bạn',
        message: 'Bạn có muốn đặt trước món ăn để không phải chờ đợi khi đến nơi?',
        restaurantName: restaurantName,
        estimatedWaitMinutes: 20,
        rating: 4.8,
        reviewCount: 2300,
        onOrderTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const FoodMenuScreen(
                placeId: placeId,
                restaurantName: restaurantName,
              ),
            ),
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
        onActivityLongPress: _navigateToPlaceDetail,
        onEditActivity: _onEditActivity,
        onReplaceActivity: _onReplaceActivity,
        onDeleteActivity: _onDeleteActivity,
        onRateActivity: _onRateActivity,
        onEditTime: _onEditTime,
        onShareTap: _showShareSheet,
        onMarkerTap: (id) => _scrollToActivity(id),
        highlightedActivityId: _highlightedActivityId,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showPreOrderDemo,
        label: Text('Demo Đặt món'),
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
  final MapboxMap? mapController;
  final Function(MapboxMap) onMapCreated;
  final ScrollController scrollController;
  final Map<String, GlobalKey> activityKeys;
  final Function(ItineraryActivityEntity) onActivityTap;
  final Function(ItineraryActivityEntity) onActivityLongPress;
  final Function(ItineraryActivityEntity) onEditActivity;
  final Function(ItineraryActivityEntity) onReplaceActivity;
  final Function(ItineraryActivityEntity) onDeleteActivity;
  final Function(ItineraryActivityEntity) onRateActivity;
  final Function(ItineraryActivityEntity, bool) onEditTime;
  final VoidCallback onShareTap;
  final Function(String) onMarkerTap;
  final String? highlightedActivityId;

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
    required this.onActivityLongPress,
    required this.onEditActivity,
    required this.onReplaceActivity,
    required this.onDeleteActivity,
    required this.onRateActivity,
    required this.onEditTime,
    required this.onShareTap,
    required this.onMarkerTap,
    this.highlightedActivityId,
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
                      child: Text('Thử lại'),
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
              orElse: () => itin.days.first,
            );

            return Stack(
              children: [
                // ✅ MAP CHIẾM TOÀN MÀN HÌNH (full-screen, tương tác hoàn toàn)
                Positioned.fill(
                  child: ItineraryMapView(
                    activities: currentDayData.activities,
                    allDays: itin.days,
                    selectedDay: selectedDay,
                    onMarkerTap: onMarkerTap,
                    onMapCreated: onMapCreated,
                  ),
                ),

                // ✅ BOTTOM SHEET KÉO LÊN/XUỐNG (DraggableScrollableSheet)
                DraggableScrollableSheet(
                  initialChildSize: 0.45,  // Mở 45% màn hình ban đầu
                  minChildSize: 0.12,      // Thu nhỏ tối đa → gần như chỉ thấy map
                  maxChildSize: 0.85,      // Mở rộng tối đa → che gần hết map
                  snap: true,
                  snapSizes: const [0.12, 0.45, 0.85],
                  builder: (context, sheetScrollController) {
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Thanh kéo (drag handle)
                          Padding(
                            padding: const EdgeInsets.only(top: 12, bottom: 8),
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          // Nội dung cuộn được
                          Expanded(
                            child: ListView(
                              controller: sheetScrollController,
                              padding: EdgeInsets.zero,
                              children: [
                                _buildContentCard(context, itin, currentDayData, itin.days),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // ✅ FLOATING BUTTONS (Back, Share, Rate) ở trên cùng
                Positioned(
                  top: MediaQuery.of(context).padding.top + AppSizes.s12,
                  left: AppSizes.s20,
                  right: AppSizes.s20,
                  child: Row(
                    children: [
                      _floatingCircleButton(Icons.arrow_back_ios_new, () => Navigator.pop(context)),
                      if (itin.status == 'COMPLETED' || itin.status == 'ONGOING' || itin.endDate.isBefore(DateTime.now()))
                        Padding(
                          padding: const EdgeInsets.only(left: AppSizes.s12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _floatingCircleButton(Icons.star_outline_rounded, () {
                                showDialog(
                                  context: context,
                                  builder: (_) => ItineraryReviewDialog(
                                      itineraryId: itin.id,
                                      itineraryTitle: itin.title,
                                      totalLocations: itin.totalLocations,
                                      visitedLocations: itin.visitedLocations,
                                  ),
                                );
                              }),
                              const SizedBox(height: 2),
                              const Text(
                                'Đánh giá',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Spacer(),
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
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: AppSizes.s16),
          ...currentDayData.activities.asMap().entries.map((entry) {
            final activity = entry.value;
            final key = activityKeys.putIfAbsent(activity.id, () => GlobalKey());
            
            return TimelineActivityCard(
              key: key,
              activity: activity,
              day: selectedDay,
              isFirst: entry.key == 0,
              isLast: entry.key == currentDayData.activities.length - 1,
              onAddTap: onAddPlaceTap,
              onEditTap: () => onEditActivity(activity),
              onReplaceTap: () => onReplaceActivity(activity),
              onDeleteTap: () => onDeleteActivity(activity),
              onRateTap: () => onRateActivity(activity),
              onCardTap: () => onActivityTap(activity),
              onCardLongPress: () => onActivityLongPress(activity),
              isHighlighted: highlightedActivityId == activity.id,
              onStartTimeTap: () => onEditTime(activity, true),
              onEndTimeTap: () => onEditTime(activity, false),
            );
          }),
          const SizedBox(height: AppSizes.s24),
          Center(
            child: OutlinedButton.icon(
              onPressed: onAddPlaceTap,
              icon: const Icon(Icons.add_location_alt_outlined, size: AppSizes.iconSm),
              label: Text('THÊM ĐỊA ĐIỂM'),
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
    return Material(
      color: Colors.black.withAlpha(120),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}