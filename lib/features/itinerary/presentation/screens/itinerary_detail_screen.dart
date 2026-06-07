import 'dart:convert';
import 'dart:math' show sqrt, sin, cos, atan2, pi;
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
import '../widgets/replace_place_sheet.dart';
import '../widgets/add_place_sheet.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:travel_advisor_mobile/core/utils/map_utils.dart';

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
  bool _isEditMode = false;
  ItineraryDetailEntity? _editSnapshot;
  MapboxMap? _mapController;
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _activityKeys = {};
  String? _highlightedActivityId;

  void _showAddPlaceScreen() {
    final state = context.read<ItineraryCubit>().state;
    double? refLat;
    double? refLng;
    String? proposedVisitTime;
    List<String> existingIds = [];

    if (state is ItineraryLoaded && state.selectedItinerary != null) {
      final itin = state.selectedItinerary!;
      for (final day in itin.days) {
        for (final act in day.activities) {
          existingIds.add(act.id);
        }
      }
      try {
        final dayData = itin.days.firstWhere((d) => d.dayNumber == _selectedDay);
        if (dayData.activities.isNotEmpty) {
          final lastActivity = dayData.activities.last;
          refLat = lastActivity.latitude;
          refLng = lastActivity.longitude;
          proposedVisitTime = lastActivity.endTime;
        }
      } catch (_) {}
    }

    // Lấy ngày tham quan để validate opening hours đúng thứ trong tuần
    DateTime? visitDate;
    if ((context.read<ItineraryCubit>().state as ItineraryLoaded?)
            ?.selectedItinerary != null) {
      try {
        final dayData = (context.read<ItineraryCubit>().state as ItineraryLoaded)
            .selectedItinerary!
            .days
            .firstWhere((d) => d.dayNumber == _selectedDay);
        visitDate = dayData.date;
      } catch (_) {}
    }

    AddPlaceSheet.show(
      context,
      referenceLat: refLat,
      referenceLng: refLng,
      existingIds: existingIds,
      visitDate: visitDate,
      proposedVisitTime: proposedVisitTime,
      onAdd: (place) {
        context.read<ItineraryCubit>().addActivityToDay(
          _selectedDay,
          place.id,
          place.name,
          lat: place.latitude,
          lng: place.longitude,
          imageUrl: place.imageUrl,
          address: place.address,
          category: place.category,
        );
      },
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

  Future<void> _launchDirections(
    ItineraryActivityEntity from,
    ItineraryActivityEntity to,
  ) async {
    if (from.latitude == null || from.longitude == null ||
        to.latitude == null || to.longitude == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không có tọa độ để chỉ đường')),
        );
      }
      return;
    }
    final url = Uri.parse(MapUtils.getDirectionsUrl(
      from.latitude!, from.longitude!,
      to.latitude!, to.longitude!,
    ));
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('_launchDirections failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở Google Maps')),
        );
      }
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

  void _onEditModeTap() async {
    if (_isEditMode) {
      final bool? confirmSave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Xác nhận cập nhật lịch trình'),
          content: const Text('Bạn có chắc chắn muốn lưu lại các mốc thời gian vừa chỉnh sửa không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Lưu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (confirmSave == true && mounted) {
        setState(() {
          _isEditMode = false;
          _editSnapshot = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã cập nhật lịch trình thành công!'),
            backgroundColor: AppColorsExt.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r12)),
          ),
        );
        context.read<ItineraryCubit>().confirmUpdateItinerary(widget.itineraryId);
      }
    } else {
      // Lưu snapshot trước khi vào edit mode để có thể hoàn tác
      final currentItinerary = (context.read<ItineraryCubit>().state as ItineraryLoaded?)
          ?.selectedItinerary;
      setState(() {
        _isEditMode = true;
        _editSnapshot = currentItinerary;
      });
    }
  }

  void _onDiscardChanges() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hủy chỉnh sửa?'),
        content: const Text('Các thay đổi chưa lưu sẽ bị mất. Bạn có chắc muốn hủy không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tiếp tục sửa', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorsExt.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Hủy thay đổi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final snapshot = _editSnapshot;
      setState(() {
        _isEditMode = false;
        _editSnapshot = null;
      });
      if (snapshot != null) {
        context.read<ItineraryCubit>().discardChanges(snapshot);
      }
    }
  }

  /// Lấy DateTime của ngày [dayNumber] từ itinerary hiện tại.
  DateTime? _visitDateForDay(int dayNumber) {
    try {
      final state = context.read<ItineraryCubit>().state;
      if (state is! ItineraryLoaded) return null;
      return state.selectedItinerary?.days
          .firstWhere((d) => d.dayNumber == dayNumber)
          .date;
    } catch (_) {
      return null;
    }
  }

  /// Parse open_hour_compressed JSON, trả về (openTime, closeTime) dạng "HH:mm" cho [date].
  (String, String)? _parseOpenSlot(String jsonStr, DateTime date) {
    try {
      const dayNames = [
        'Monday', 'Tuesday', 'Wednesday', 'Thursday',
        'Friday', 'Saturday', 'Sunday'
      ];
      final Map<String, dynamic> map = jsonDecode(jsonStr);
      final slots = map[dayNames[date.weekday - 1]] as List?;
      if (slots == null || slots.isEmpty) return null;
      final slot = slots[0] as List;
      return (
        (slot[0] as String).substring(0, 5),
        (slot[1] as String).substring(0, 5),
      );
    } catch (_) {
      return null;
    }
  }

  void _onEditActivity(ItineraryActivityEntity activity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActivityEditScreen(activity: activity),
      ),
    );
  }

  void _onEditTime(ItineraryActivityEntity activity, bool isStart, bool isLastInDay) async {
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
      final currentTime = isStart ? activity.startTime : activity.endTime;

      // ── Validation: kiểm tra tính hợp lệ trước khi cho phép thay đổi ──────
      final newMin = pickedTime.hour * 60 + pickedTime.minute;

      int _toMinutes(String t) {
        final p = t.split(':');
        return int.parse(p[0]) * 60 + int.parse(p[1]);
      }

      Future<void> _showTimeError(String message) async {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(children: [
              const Icon(Icons.error_outline, color: Color(0xFFEF4444)),
              const SizedBox(width: 8),
              const Expanded(child: Text('Thời gian không hợp lệ')),
            ]),
            content: Text(message),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Đã hiểu', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      }

      if (isStart) {
        // Đang chỉnh giờ ĐẾN → phải trước giờ RỜI hiện tại
        final endMin = _toMinutes(activity.endTime);
        if (newMin >= endMin) {
          await _showTimeError(
            'Giờ đến ($newTime) phải trước giờ rời (${activity.endTime}) của cùng địa điểm.\n\n'
            'Vui lòng chọn lại thời gian.',
          );
          return; // Không áp dụng thay đổi
        }
        if (endMin - newMin > 4 * 60) {
          await _showTimeError(
            'Khoảng thời gian tham quan quá dài (hơn 4 tiếng).\n\n'
            'Vui lòng chọn giờ đến hợp lý hơn.',
          );
          return;
        }
      } else {
        // Đang chỉnh giờ RỜI → phải sau giờ ĐẾN hiện tại
        final startMin = _toMinutes(activity.startTime);
        if (newMin <= startMin) {
          await _showTimeError(
            'Giờ rời ($newTime) phải sau giờ đến (${activity.startTime}) của cùng địa điểm.\n\n'
            'Vui lòng chọn lại thời gian.',
          );
          return; // Không áp dụng thay đổi
        }
        if (newMin - startMin > 4 * 60) {
          await _showTimeError(
            'Khoảng thời gian tham quan quá dài (hơn 4 tiếng).\n\n'
            'Vui lòng chọn giờ rời hợp lý hơn.',
          );
          return;
        }
      }
      // ── Validate giờ mở/đóng cửa của địa điểm ─────────────────────────────────
      if (activity.openHourCompressed != null) {
        final visitDate = _visitDateForDay(_selectedDay);
        if (visitDate != null) {
          final slot = _parseOpenSlot(activity.openHourCompressed!, visitDate);
          if (slot != null) {
            int toM(String t) {
              final p = t.split(':');
              return int.parse(p[0]) * 60 + int.parse(p[1]);
            }
            final openMin  = toM(slot.$1);
            final closeMin = toM(slot.$2);
            final label = isStart ? 'đến' : 'rời';
            if (newMin < openMin) {
              await _showTimeError(
                '${activity.title} chưa mở cửa lúc $newTime.\n\n'
                'Địa điểm mở cửa từ ${slot.$1} – ${slot.$2}. Vui lòng chọn giờ $label sau ${slot.$1}.',
              );
              return;
            }
            if (newMin > closeMin) {
              await _showTimeError(
                '${activity.title} đã đóng cửa lúc ${slot.$2}.\n\n'
                'Giờ $label $newTime vượt quá giờ đóng cửa. Vui lòng chọn trước ${slot.$2}.',
              );
              return;
            }
          }
        }
      }
      // ── Kết thúc validation ──────────────────────────────────────────────────

      if (newTime != currentTime) {
        final oldMin = int.parse(parts[0]) * 60 + int.parse(parts[1]);
        final deltaMin = newMin - oldMin;

        final bool hasSubsequent = !(isLastInDay && !isStart);

        if (hasSubsequent) {
          final timeLabel = isStart ? 'thời gian đến' : 'thời gian rời';

          final bool? shouldAdjustSubsequent = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Tự động điều chỉnh thời gian?'),
              content: Text(
                'Bạn vừa thay đổi $timeLabel từ $currentTime sang $newTime (${deltaMin > 0 ? "+" : ""}$deltaMin phút).\n\n'
                'Bạn có muốn tự động điều chỉnh (tịnh tiến) các địa điểm phía sau không?'
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Không', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Có', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );

          if (shouldAdjustSubsequent == true && mounted) {
            context.read<ItineraryCubit>().updateActivityTimesWithShift(
                  activityId: activity.id,
                  deltaMinutes: deltaMin,
                  shiftStartTimeOnly: isStart,
                );
            return;
          }
        }
      }

      if (!mounted) return;
      context.read<ItineraryCubit>().updateActivityTimeSingle(
            activity.id,
            startTime: isStart ? newTime : null,
            endTime: isStart ? null : newTime,
          );
    }
  }


  void _onReplaceActivity(ItineraryActivityEntity activity) {
    List<String> existingIds = [];
    final state = context.read<ItineraryCubit>().state;
    if (state is ItineraryLoaded && state.selectedItinerary != null) {
      for (final day in state.selectedItinerary!.days) {
        for (final act in day.activities) {
          existingIds.add(act.id);
        }
      }
    }

    ReplacePlaceSheet.show(
      context,
      activity: activity,
      existingIds: existingIds,
      onReplace: (place) {
        context.read<ItineraryCubit>().replaceActivity(
          activity.id,
          place.id,
          place.name,
          newLat: place.latitude,
          newLng: place.longitude,
          newImageUrl: place.imageUrl,
          newRating: place.rating,
          newReviewCount: place.reviewCount,
          newAddress: place.address,
          newCategory: place.category,
        );
      },
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
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa địa điểm'),
        content: Text('Bạn có chắc chắn muốn xóa "${activity.title}" khỏi lịch trình không?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<ItineraryCubit>().deleteActivity(activity.id);
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

  void _showReorderSuggestionBanner() {
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.s20, vertical: AppSizes.s8),
        content: const Text(
          'Có lộ trình tối ưu hơn cho ngày này. Bạn có muốn áp dụng không?',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              context.read<ItineraryCubit>().dismissReorderSuggestion();
            },
            child: const Text('Giữ nguyên',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              context.read<ItineraryCubit>().applySuggestedReorder();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Đã áp dụng lộ trình tối ưu!'),
                  backgroundColor: AppColorsExt.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.r12)),
                ),
              );
            },
            child: Text('Sắp xếp lại',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ItineraryCubit, ItineraryState>(
      listenWhen: (prev, curr) {
        final hasSuggestion = curr is ItineraryLoaded && curr.suggestedDays != null;
        final wasNoSuggestion = prev is! ItineraryLoaded || prev.suggestedDays == null;
        return hasSuggestion && wasNoSuggestion;
      },
      listener: (context, _) => _showReorderSuggestionBanner(),
      child: Scaffold(
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
        onDirectionTap: _launchDirections,
        onShareTap: _showShareSheet,
        onMarkerTap: (id) => _scrollToActivity(id),
        highlightedActivityId: _highlightedActivityId,
        isEditMode: _isEditMode,
        onEditModeTap: _onEditModeTap,
        onDiscardTap: _onDiscardChanges,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showPreOrderDemo,
        label: Text('Demo Đặt món'),
        icon: const Icon(Icons.restaurant),
        backgroundColor: AppColors.primary,
      ),
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
  final Function(ItineraryActivityEntity, bool, bool) onEditTime;
  final Function(ItineraryActivityEntity, ItineraryActivityEntity) onDirectionTap;
  final VoidCallback onShareTap;
  final Function(String) onMarkerTap;
  final String? highlightedActivityId;
  final bool isEditMode;
  final VoidCallback onEditModeTap;
  final VoidCallback onDiscardTap;

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
    required this.onDirectionTap,
    required this.onShareTap,
    required this.onMarkerTap,
    this.highlightedActivityId,
    required this.isEditMode,
    required this.onEditModeTap,
    required this.onDiscardTap,
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
                          child: _floatingCircleButton(Icons.star_outline_rounded, () {
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
                        ),
                      const Spacer(),
                      if (isEditMode) ...[
                        _floatingCircleButton(
                          Icons.close_rounded,
                          onDiscardTap,
                          iconColor: const Color(0xFFEF4444),
                        ),
                        const SizedBox(width: AppSizes.s12),
                      ],
                      _floatingCircleButton(
                        isEditMode ? Icons.check_rounded : Icons.edit_outlined,
                        onEditModeTap,
                        active: isEditMode,
                      ),
                      if (!isEditMode) ...[
                        const SizedBox(width: AppSizes.s12),
                        _floatingCircleButton(Icons.share_outlined, onShareTap),
                      ],
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
          Row(
            children: [
              Text(
                '${currentDayData.locationsCount} điểm tham quan du lịch',
                style: AppTextStylesExt.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onAddPlaceTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.30),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Thêm địa điểm',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.s16),
          ...currentDayData.activities.asMap().entries.map((entry) {
            final index = entry.key;
            final activity = entry.value;
            final activities = currentDayData.activities;
            final key = activityKeys.putIfAbsent(activity.id, () => GlobalKey());
            final nextActivity = index < activities.length - 1 ? activities[index + 1] : null;
            final nextTransport = nextActivity == null
                ? null
                : (activities[index].transportInfo?.isNotEmpty == true
                    ? activities[index].transportInfo
                    : _estimateTransit(
                        activity.latitude, activity.longitude,
                        nextActivity.latitude, nextActivity.longitude,
                      ));

            return TimelineActivityCard(
              key: key,
              activity: activity,
              day: selectedDay,
              isFirst: index == 0,
              isLast: index == activities.length - 1,
              nextTransportInfo: nextTransport,
              onAddTap: onAddPlaceTap,
              onEditTap: () => onEditActivity(activity),
              onReplaceTap: () => onReplaceActivity(activity),
              onDeleteTap: () => onDeleteActivity(activity),
              onRateTap: () => onRateActivity(activity),
              onCardTap: () => onActivityTap(activity),
              onCardLongPress: () => onActivityLongPress(activity),
              isHighlighted: highlightedActivityId == activity.id,
              onStartTimeTap: () => onEditTime(activity, true, index == activities.length - 1),
              onEndTimeTap: () => onEditTime(activity, false, index == activities.length - 1),
              isEditMode: isEditMode,
              onDirectionTap: nextActivity != null
                  ? () => onDirectionTap(activity, nextActivity)
                  : null,
            );
          }),
          const SizedBox(height: AppSizes.s40),
        ],
      ),
    );
  }


  // Ước tính thời gian di chuyển từ tọa độ (Haversine + tốc độ 25 km/h)
  static String _estimateTransit(
    double? lat1, double? lng1,
    double? lat2, double? lng2,
  ) {
    if (lat1 == null || lng1 == null || lat2 == null || lng2 == null) {
      return 'Di chuyển đến điểm tiếp theo';
    }
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
            sin(dLng / 2) * sin(dLng / 2);
    final km = r * 2 * atan2(sqrt(a), sqrt(1 - a));
    final mins = (km / 25 * 60).ceil().clamp(1, 999);
    if (mins < 60) return '~$mins phút di chuyển';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '~$h giờ di chuyển' : '~$h giờ $m phút di chuyển';
  }

  Widget _floatingCircleButton(IconData icon, VoidCallback onTap, {bool active = false, Color? iconColor}) {
    return Material(
      color: active ? AppColors.primary.withAlpha(220) : Colors.black.withAlpha(120),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 18, color: iconColor ?? Colors.white),
        ),
      ),
    );
  }
}