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
    if (activity.latitude != null && activity.longitude != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(activity.latitude!, activity.longitude!),
          15,
        ),
      );
    }
    
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
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r16)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.s20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tùy chọn địa điểm',
                style: AppTextStyles.heading2.copyWith(fontSize: 18),
              ),
              const SizedBox(height: AppSizes.s24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit_note_rounded, color: AppColors.primary),
                ),
                title: Text('Chỉnh sửa thông tin địa điểm', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (context) => Padding(
                      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                      child: EditTimeBottomSheet(activity: activity),
                    ),
                  );
                },
              ),
              const Divider(height: 24, color: AppColorsExt.divider),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColorsExt.profileBlue.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.swap_horiz_rounded, color: AppColorsExt.profileBlue),
                ),
                title: Text('Thay thế địa điểm', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Tính năng thay thế địa điểm sẽ sớm ra mắt!'),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r12)),
                    ),
                  );
                },
              ),
            ],
          ),
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
        onEditActivity: _onEditActivity,
        onDeleteActivity: _onDeleteActivity,
        onShareTap: _showShareSheet,
        onMarkerTap: (id) => _scrollToActivity(id),
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
  final GoogleMapController? mapController;
  final Function(GoogleMapController) onMapCreated;
  final ScrollController scrollController;
  final Map<String, GlobalKey> activityKeys;
  final Function(ItineraryActivityEntity) onActivityTap;
  final Function(ItineraryActivityEntity) onEditActivity;
  final Function(ItineraryActivityEntity) onDeleteActivity;
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
    required this.onEditActivity,
    required this.onDeleteActivity,
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
                      child: Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is ItineraryLoaded && state.selectedItinerary != null) {
            final itin = state.selectedItinerary!;
            final displayDays = _getDisplayDays(itin);
            final currentDayData = displayDays.firstWhere(
              (d) => d.dayNumber == selectedDay, 
              orElse: () => displayDays.first,
            );

            return Stack(
              children: [
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
                ),
                
                SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    children: [
                      const SizedBox(height: 280),
                      _buildContentCard(context, itin, currentDayData, displayDays),
                    ],
                  ),
                ),
                
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

  List<ItineraryDayEntity> _getDisplayDays(ItineraryDetailEntity itin) {
    final List<ItineraryDayEntity> displayDays = List.from(itin.days);
    if (displayDays.length < 3) {
      final firstDayDate = displayDays.isNotEmpty ? displayDays.first.date : DateTime.now();
      
      final mockActivitiesDay2 = [
        ItineraryActivityEntity(
          id: 'mock_2_1',
          title: 'Bảo tàng Chứng tích Chiến tranh',
          locationName: 'Quận 3',
          address: '28 Võ Văn Tần, Phường Võ Thị Sáu, Quận 3, TP. HCM',
          startTime: '08:30',
          endTime: '10:30',
          imageUrl: 'https://images.unsplash.com/photo-1599708153386-62e200399066?w=600&q=80',
          transportInfo: '15 phút di chuyển',
        ),
        ItineraryActivityEntity(
          id: 'mock_2_2',
          title: 'Dinh Độc Lập',
          locationName: 'Quận 1',
          address: '135 Nam Kỳ Khởi Nghĩa, Phường Bến Thành, Quận 1, TP. HCM',
          startTime: '10:45',
          endTime: '12:45',
          imageUrl: 'https://images.unsplash.com/photo-1559506825-f933e38714eb?w=600&q=80',
          transportInfo: '10 phút di chuyển',
        ),
      ];

      final mockActivitiesDay3 = [
        ItineraryActivityEntity(
          id: 'mock_3_1',
          title: 'Chợ Bến Thành',
          locationName: 'Quận 1',
          address: 'Đường Lê Lợi, Phường Bến Thành, Quận 1, TP. HCM',
          startTime: '09:00',
          endTime: '11:00',
          imageUrl: 'https://images.unsplash.com/photo-1583417319070-4a69db38a482?w=600&q=80',
          transportInfo: '20 phút di chuyển',
        ),
      ];

      for (int i = displayDays.length + 1; i <= 3; i++) {
        displayDays.add(ItineraryDayEntity(
          dayNumber: i,
          date: firstDayDate.add(Duration(days: i - 1)),
          temperature: 28 + i,
          totalDuration: i == 2 ? '8 giờ 15 phút' : '6 giờ 30 phút',
          locationsCount: i == 2 ? 2 : 1,
          dayBudget: 350000.0 * i,
          activities: i == 2 ? mockActivitiesDay2 : mockActivitiesDay3,
        ));
      }
    }
    return displayDays;
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
              color: const Color(0xFF94A3B8),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: AppSizes.s16),
          ...currentDayData.activities.asMap().entries.map((entry) {
            final activity = entry.value;
            final key = activityKeys.putIfAbsent(activity.id, () => GlobalKey());
            
            return GestureDetector(
              key: key,
              onTap: () => onActivityTap(activity),
              child: TimelineActivityCard(
                activity: activity,
                isFirst: entry.key == 0,
                isLast: entry.key == currentDayData.activities.length - 1,
                onAddTap: onAddPlaceTap,
                onEditTap: () => onEditActivity(activity),
                onDeleteTap: () => onDeleteActivity(activity),
              ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
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

class EditTimeBottomSheet extends StatefulWidget {
  final ItineraryActivityEntity activity;

  const EditTimeBottomSheet({super.key, required this.activity});

  @override
  State<EditTimeBottomSheet> createState() => _EditTimeBottomSheetState();
}

class _EditTimeBottomSheetState extends State<EditTimeBottomSheet> {
  late int _durationMinutes;
  late TextEditingController _hourController;
  late TextEditingController _minuteController;
  late FocusNode _hourFocus;
  late FocusNode _minuteFocus;

  TimeOfDay? _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    final arrival = _parseTime(widget.activity.startTime) ?? const TimeOfDay(hour: 8, minute: 0);
    _hourController = TextEditingController(text: arrival.hour.toString().padLeft(2, '0'));
    _minuteController = TextEditingController(text: arrival.minute.toString().padLeft(2, '0'));
    _hourFocus = FocusNode();
    _minuteFocus = FocusNode();

    final end = _parseTime(widget.activity.endTime) ?? const TimeOfDay(hour: 9, minute: 0);
    int startMins = arrival.hour * 60 + arrival.minute;
    int endMins = end.hour * 60 + end.minute;
    if (endMins < startMins) endMins += 24 * 60;
    _durationMinutes = endMins - startMins;
    if (_durationMinutes <= 0) _durationMinutes = 60;
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _hourFocus.dispose();
    _minuteFocus.dispose();
    super.dispose();
  }

  void _validateAndFormat() {
    int h = int.tryParse(_hourController.text) ?? 8;
    int m = int.tryParse(_minuteController.text) ?? 0;
    if (h > 23) h = 23;
    if (m > 59) m = 59;
    _hourController.text = h.toString().padLeft(2, '0');
    _minuteController.text = m.toString().padLeft(2, '0');
  }

  String _formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}p';
    if (h > 0) return '${h}h';
    return '${m}p';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.r24)),
      ),
      padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24, top: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColorsExt.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Chỉnh sửa thông tin địa điểm',
            style: AppTextStyles.heading2.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text('Thời gian đến', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _timeInputBox(_hourController, _hourFocus, 23, (val) {
                    if (val.length == 2) _minuteFocus.requestFocus();
                  }),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(':', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ),
                  _timeInputBox(_minuteController, _minuteFocus, 59, (val) {
                    if (val.length == 2) FocusScope.of(context).unfocus();
                  }),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text('Thời gian tham quan', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColorsExt.searchBarBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.remove_circle_outline, size: 24),
                      color: _durationMinutes > 15 ? AppColors.textPrimary : AppColorsExt.divider,
                      onPressed: () {
                        if (_durationMinutes > 15) {
                          setState(() => _durationMinutes -= 15);
                        }
                      },
                    ),
                    Container(
                      width: 75,
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      alignment: Alignment.center,
                      child: Text(
                        _formatDuration(_durationMinutes),
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, fontSize: 15),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.add_circle_outline, size: 24),
                      color: AppColors.textPrimary,
                      onPressed: () {
                        setState(() => _durationMinutes += 15);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: AppSizes.buttonHeight,
            child: ElevatedButton(
              onPressed: () {
                _validateAndFormat();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Đã cập nhật thời gian tham quan!'),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r12)),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.r12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Lưu thay đổi',
                style: AppTextStyles.heading2.copyWith(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeInputBox(
    TextEditingController controller,
    FocusNode focusNode,
    int maxValue,
    Function(String) onChanged,
  ) {
    return Container(
      width: 40,
      height: 32,
      decoration: BoxDecoration(
        color: AppColorsExt.searchBarBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: AppTextStyles.body.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          fontSize: 15,
        ),
        maxLength: 2,
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (val) {
          if (val.isNotEmpty) {
            final num = int.tryParse(val);
            if (num != null && num > maxValue) {
              controller.text = maxValue.toString();
              controller.selection = TextSelection.fromPosition(
                TextPosition(offset: controller.text.length),
              );
            }
          }
          onChanged(val);
        },
      ),
    );
  }
}
