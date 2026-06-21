import 'dart:convert';
import 'dart:math' show sqrt, sin, cos, atan2, pi;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'activity_edit_screen.dart';

import 'package:travel_advisor_mobile/core/constants/app_colors.dart';
import 'package:travel_advisor_mobile/core/constants/app_sizes.dart';
import 'package:travel_advisor_mobile/core/constants/app_text_styles.dart';
import 'package:travel_advisor_mobile/core/di/injection_container.dart';
import 'package:travel_advisor_mobile/core/utils/demo_review_store.dart';
import 'package:travel_advisor_mobile/features/food/presentation/screens/food_menu_screen.dart';
import 'package:travel_advisor_mobile/features/food/presentation/widgets/pre_order_popup.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_activity_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_day_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/tracking/presentation/cubit/tracking_cubit.dart';
import 'package:travel_advisor_mobile/features/itinerary/tracking/presentation/cubit/tracking_state.dart';
import 'package:travel_advisor_mobile/features/itinerary/tracking/data/models/tracking_models.dart';
import 'package:travel_advisor_mobile/features/itinerary/tracking/presentation/widgets/tracking_section.dart';
import 'package:travel_advisor_mobile/features/itinerary/tracking/tracking_config.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_detail_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/cubit/itinerary_cubit.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/cubit/itinerary_state.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/widgets/day_selector_chip.dart';
import 'package:travel_advisor_mobile/features/review/presentation/widgets/itinerary_rating_popup.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/widgets/timeline_activity_card.dart';
import 'package:travel_advisor_mobile/features/place/presentation/cubit/place_detail_cubit.dart';
import 'package:travel_advisor_mobile/features/place/presentation/screens/place_detail_screen.dart';
import 'package:travel_advisor_mobile/features/saved/data/datasources/favorite_remote_datasource.dart';
import '../widgets/itinerary_map_view.dart';
import '../widgets/replace_place_sheet.dart';
import '../widgets/add_place_sheet.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:travel_advisor_mobile/core/utils/map_utils.dart';

class ItineraryDetailScreen extends StatefulWidget {
  final String itineraryId;
  final ItineraryDetailEntity? initialDetail;
  final int initialDay;

  const ItineraryDetailScreen({
    super.key,
    required this.itineraryId,
    this.initialDetail,
    this.initialDay = 1,
  });

  @override
  State<ItineraryDetailScreen> createState() => _ItineraryDetailScreenState();
}

class _ItineraryDetailScreenState extends State<ItineraryDetailScreen> {
  late int _selectedDay = widget.initialDay;
  bool _isPublic = true;
  bool _isEditMode = false;
  bool _isMapLoaded = false;
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
        final dayData = itin.days.firstWhere(
          (d) => d.dayNumber == _selectedDay,
        );
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
            ?.selectedItinerary !=
        null) {
      try {
        final dayData =
            (context.read<ItineraryCubit>().state as ItineraryLoaded)
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
    final itin = (context.read<ItineraryCubit>().state as ItineraryLoaded)
        .selectedItinerary;
    final activity = itin?.days
        .expand((d) => d.activities)
        .firstWhere((a) => a.id == activityId);
    if (activity != null &&
        activity.latitude != null &&
        activity.longitude != null) {
      _mapController?.setCamera(
        CameraOptions(
          center: Point(
            coordinates: Position(activity.longitude!, activity.latitude!),
          ),
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
          center: Point(
            coordinates: Position(activity.longitude!, activity.latitude!),
          ),
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
    if (from.latitude == null ||
        from.longitude == null ||
        to.latitude == null ||
        to.longitude == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không có tọa độ để chỉ đường')),
        );
      }
      return;
    }
    final url = Uri.parse(
      MapUtils.getDirectionsUrl(
        from.latitude!,
        from.longitude!,
        to.latitude!,
        to.longitude!,
      ),
    );
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
    final placeId = activity.placeId ?? activity.id;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => sl<PlaceDetailCubit>(),
          child: PlaceDetailScreen(
            placeId: placeId,
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Xác nhận cập nhật lịch trình'),
          content: const Text(
            'Bạn có chắc chắn muốn lưu lại các mốc thời gian vừa chỉnh sửa không?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Hủy',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Lưu',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.r12),
            ),
          ),
        );
        context.read<ItineraryCubit>().confirmUpdateItinerary(
          widget.itineraryId,
        );
      }
    } else {
      // Lưu snapshot trước khi vào edit mode để có thể hoàn tác
      final currentItinerary =
          (context.read<ItineraryCubit>().state as ItineraryLoaded?)
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
        content: const Text(
          'Các thay đổi chưa lưu sẽ bị mất. Bạn có chắc muốn hủy không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Tiếp tục sửa',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorsExt.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Hủy thay đổi',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
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
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
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
      MaterialPageRoute(builder: (_) => ActivityEditScreen(activity: activity)),
    );
  }

  Future<void> _toggleItineraryFavorite() async {
    final state = context.read<ItineraryCubit>().state;
    if (state is! ItineraryLoaded || state.selectedItinerary == null) {
      return;
    }

    final itinerary = state.selectedItinerary!;
    if (!itinerary.isPublic) {
      return;
    }

    final nextFavorite = !itinerary.isFavorite;
    context.read<ItineraryCubit>().setSelectedItineraryFavorite(nextFavorite);

    try {
      await sl<FavoriteRemoteDataSource>().setItineraryFavorite(
        itinerary.id,
        nextFavorite,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextFavorite
                ? 'Đã lưu vào danh mục yêu thích'
                : 'Đã bỏ khỏi danh mục yêu thích',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      context.read<ItineraryCubit>().setSelectedItineraryFavorite(
        itinerary.isFavorite,
      );
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa thể cập nhật yêu thích, vui lòng thử lại'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onEditTime(
    ItineraryActivityEntity activity,
    bool isStart,
    bool isLastInDay,
  ) async {
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
      final newTime =
          '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
      final currentTime = isStart ? activity.startTime : activity.endTime;

      // ── Validation: kiểm tra tính hợp lệ trước khi cho phép thay đổi ──────
      final newMin = pickedTime.hour * 60 + pickedTime.minute;

      int toMinutes(String t) {
        final p = t.split(':');
        return int.parse(p[0]) * 60 + int.parse(p[1]);
      }

      Future<void> showTimeError(String message) async {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(Icons.error_outline, color: Color(0xFFEF4444)),
                const SizedBox(width: 8),
                const Expanded(child: Text('Thời gian không hợp lệ')),
              ],
            ),
            content: Text(message),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Đã hiểu',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      }

      if (isStart) {
        // Đang chỉnh giờ ĐẾN → phải trước giờ RỜI hiện tại
        final endMin = toMinutes(activity.endTime);
        if (newMin >= endMin) {
          await showTimeError(
            'Giờ đến ($newTime) phải trước giờ rời (${activity.endTime}) của cùng địa điểm.\n\n'
            'Vui lòng chọn lại thời gian.',
          );
          return; // Không áp dụng thay đổi
        }
        if (endMin - newMin > 4 * 60) {
          await showTimeError(
            'Khoảng thời gian tham quan quá dài (hơn 4 tiếng).\n\n'
            'Vui lòng chọn giờ đến hợp lý hơn.',
          );
          return;
        }
      } else {
        // Đang chỉnh giờ RỜI → phải sau giờ ĐẾN hiện tại
        final startMin = toMinutes(activity.startTime);
        if (newMin <= startMin) {
          await showTimeError(
            'Giờ rời ($newTime) phải sau giờ đến (${activity.startTime}) của cùng địa điểm.\n\n'
            'Vui lòng chọn lại thời gian.',
          );
          return; // Không áp dụng thay đổi
        }
        if (newMin - startMin > 4 * 60) {
          await showTimeError(
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

            final openMin = toM(slot.$1);
            final closeMin = toM(slot.$2);
            final label = isStart ? 'đến' : 'rời';
            if (newMin < openMin) {
              await showTimeError(
                '${activity.title} chưa mở cửa lúc $newTime.\n\n'
                'Địa điểm mở cửa từ ${slot.$1} – ${slot.$2}. Vui lòng chọn giờ $label sau ${slot.$1}.',
              );
              return;
            }
            if (newMin > closeMin) {
              await showTimeError(
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Tự động điều chỉnh thời gian?'),
              content: Text(
                'Bạn vừa thay đổi $timeLabel từ $currentTime sang $newTime (${deltaMin > 0 ? "+" : ""}$deltaMin phút).\n\n'
                'Bạn có muốn tự động điều chỉnh (tịnh tiến) các địa điểm phía sau không?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(
                    'Không',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Có',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
    final TextEditingController commentController = TextEditingController(
      text: DemoReviewStore.userComments[activity.id] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Đánh giá ${activity.title}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Bạn cảm thấy địa điểm này thế nào?',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < currentRating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
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
                  DemoReviewStore.saveLocationRating(
                    activity.id,
                    currentRating,
                    comment: commentController.text,
                  );
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
        content: Text(
          'Bạn có chắc chắn muốn xóa "${activity.title}" khỏi lịch trình không?',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.r16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Hủy',
              style: TextStyle(color: AppColors.textSecondary),
            ),
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
            child: const Text(
              'Xóa',
              style: TextStyle(
                color: AppColorsExt.error,
                fontWeight: FontWeight.bold,
              ),
            ),
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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSizes.r32),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.s24,
              vertical: AppSizes.s16,
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColorsExt.divider,
                    borderRadius: BorderRadius.circular(AppSizes.s2),
                  ),
                ),
                const SizedBox(height: AppSizes.s24),
                Text('Chia sẻ lịch trình', style: AppTextStyles.heading2),
                const SizedBox(height: AppSizes.s8),
                Text(
                  'Mời bạn bè cùng tham gia và chỉnh sửa lịch trình chung cho chuyến đi này.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSizes.s24),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm qua tên hoặc email...',
                    prefixIcon: const Icon(Icons.search, size: AppSizes.iconMd),
                    filled: true,
                    fillColor: AppColorsExt.searchBarBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.r16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: AppSizes.s16,
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.s24),
                Expanded(
                  child: ListView(
                    children: [
                      _shareUserItem(
                        'Nguyễn Văn A',
                        'anv@example.com',
                        'https://i.pravatar.cc/150?u=a',
                        invitedUsers.contains('a'),
                        () {
                          setModalState(() => invitedUsers.add('a'));
                        },
                      ),
                      _shareUserItem(
                        'Trần Thị B',
                        'btt@example.com',
                        'https://i.pravatar.cc/150?u=b',
                        invitedUsers.contains('b'),
                        () {
                          setModalState(() => invitedUsers.add('b'));
                        },
                      ),
                      _shareUserItem(
                        'Lê Văn C',
                        'clv@example.com',
                        'https://i.pravatar.cc/150?u=c',
                        invitedUsers.contains('c'),
                        () {
                          setModalState(() => invitedUsers.add('c'));
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _shareUserItem(
    String name,
    String email,
    String avatar,
    bool isInvited,
    VoidCallback onInvite,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(avatar),
            radius: AppSizes.iconMd,
          ),
          const SizedBox(width: AppSizes.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  email,
                  style: AppTextStylesExt.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: isInvited ? null : onInvite,
            style: ElevatedButton.styleFrom(
              backgroundColor: isInvited
                  ? AppColorsExt.divider
                  : AppColors.primary,
              foregroundColor: isInvited
                  ? AppColors.textSecondary
                  : AppColors.surface,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.r12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.s16),
            ),
            child: Text(
              isInvited ? 'Đã gửi' : 'Gửi lời mời',
              style: AppTextStylesExt.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.s20,
          vertical: AppSizes.s8,
        ),
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
            child: const Text(
              'Giữ nguyên',
              style: TextStyle(color: AppColors.textSecondary),
            ),
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
                    borderRadius: BorderRadius.circular(AppSizes.r12),
                  ),
                ),
              );
            },
            child: Text(
              'Sắp xếp lại',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TrackingCubit, TrackingState>(
      listenWhen: (p, c) =>
          c.nearbyRestaurantName != null &&
          c.nearbyRestaurantName != p.nearbyRestaurantName,
      listener: (ctx, state) => _showFoodProximityPopup(ctx, state),
      child: BlocListener<ItineraryCubit, ItineraryState>(
        listenWhen: (prev, curr) {
          final hasSuggestion =
              curr is ItineraryLoaded && curr.suggestedDays != null;
          final wasNoSuggestion =
              prev is! ItineraryLoaded || prev.suggestedDays == null;
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
            isMapLoaded: _isMapLoaded,
            onLoadMapTap: () => setState(() => _isMapLoaded = true),
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
            onFavoriteTap: _toggleItineraryFavorite,
            onMarkerTap: (id) => _scrollToActivity(id),
            highlightedActivityId: _highlightedActivityId,
            isEditMode: _isEditMode,
            onEditModeTap: _onEditModeTap,
            onDiscardTap: _onDiscardChanges,
          ),
        ),
      ),
    );
  }

  void _showFoodProximityPopup(BuildContext ctx, TrackingState state) {
    final name = state.nearbyRestaurantName ?? 'Quán ăn gần đây';
    final detailId = state.nearbyRestaurantDetailId ?? '';
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PreOrderPopup(
        title: 'Quán ăn gần bạn!',
        message:
            'Bạn đang trong bán kính ${TrackingConfig.foodProximityKm.toInt()} km. Đặt trước để không phải chờ?',
        restaurantName: name,
        estimatedWaitMinutes: 15,
        rating: 0,
        reviewCount: 0,
        onOrderTap: () {
          Navigator.pop(ctx);
          ctx.read<TrackingCubit>().dismissNearbyRestaurant();
          Navigator.push(
            ctx,
            MaterialPageRoute(
              builder: (_) =>
                  FoodMenuScreen(placeId: detailId, restaurantName: name),
            ),
          );
        },
        onSkipTap: () {
          Navigator.pop(ctx);
          ctx.read<TrackingCubit>().dismissNearbyRestaurant();
        },
      ),
    ).then((_) {
      // Đóng popup → dismiss để không hiện lại ngay
      if (ctx.mounted) {
        ctx.read<TrackingCubit>().dismissNearbyRestaurant();
      }
    });
  }
}

class _DayCostSummaryCard extends StatelessWidget {
  final ItineraryDayEntity day;
  final List<ItineraryActivityEntity> visitActivities;
  final bool Function(ItineraryActivityEntity activity) isHotelStart;

  const _DayCostSummaryCard({
    required this.day,
    required this.visitActivities,
    required this.isHotelStart,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    final hotelCost = day.activities
        .where(isHotelStart)
        .fold<double>(0, (sum, activity) => sum + activity.price);
    final placeCost = visitActivities.fold<double>(
      0,
      (sum, activity) => sum + activity.price,
    );
    final selfDriveCost = (day.dayBudget - hotelCost - placeCost)
        .clamp(0, double.infinity)
        .toDouble();
    final visitedCount = visitActivities
        .where((activity) => activity.status == ActivityStatus.daDi)
        .length;
    final totalCost = day.dayBudget > 0
        ? day.dayBudget
        : placeCost + hotelCost + selfDriveCost;

    String money(double value) => '${formatter.format(value)} ${day.currency}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Chi ph\u00ed trong ng\u00e0y',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Text(
                '$visitedCount/${visitActivities.length} \u0111\u00e3 \u0111i',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DayCostRow(
            icon: Icons.receipt_long_rounded,
            label: 'T\u1ed5ng ng\u00e0y',
            value: money(totalCost),
            color: const Color(0xFF10B981),
          ),
          _DayCostRow(
            icon: Icons.place_rounded,
            label: '\u0110\u1ecba \u0111i\u1ec3m & \u0103n u\u1ed1ng',
            value: money(placeCost),
            color: const Color(0xFFF59E0B),
          ),
          _DayCostRow(
            icon: Icons.hotel_rounded,
            label: 'L\u01b0u tr\u00fa',
            value: money(hotelCost),
            color: const Color(0xFF0F766E),
          ),
          _DayCostRow(
            icon: Icons.two_wheeler_rounded,
            label: 'X\u0103ng xe/t\u1ef1 t\u00fac',
            value: money(selfDriveCost),
            color: const Color(0xFF2563EB),
          ),
        ],
      ),
    );
  }
}

class _DayCostRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DayCostRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569),
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

class _LazyMapPreview extends StatelessWidget {
  final ItineraryDayEntity day;
  final VoidCallback onLoadMapTap;

  const _LazyMapPreview({required this.day, required this.onLoadMapTap});

  @override
  Widget build(BuildContext context) {
    final pointCount = day.activities.where((activity) {
      final sameTime = activity.startTime == activity.endTime;
      final category = (activity.category ?? '').toLowerCase();
      final title = activity.title.toLowerCase();
      final isHotel =
          category.contains('lưu trú') ||
          category.contains('khách sạn') ||
          category.contains('hotel') ||
          title.contains('hotel') ||
          title.contains('khách sạn');
      return !(sameTime && isHotel);
    }).length;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEFF6FF), Color(0xFFF8FAFC)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.28,
              child: CustomPaint(painter: _MapPreviewGridPainter()),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 72,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.map_rounded,
                      color: Color(0xFF2563EB),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Ngày ${day.dayNumber} • $pointCount điểm',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Bản đồ sẽ chỉ tải khi bạn cần xem tuyến đường.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: onLoadMapTap,
                    icon: const Icon(Icons.route_rounded, size: 18),
                    label: const Text('Xem'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPreviewGridPainter extends CustomPainter {
  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    const gap = 42.0;
    for (double x = -gap; x < size.width + gap; x += gap) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
    for (double y = 0; y < size.height + gap; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y - size.width), paint);
    }

    final routePaint = Paint()
      ..color = const Color(0xFFF97316)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width * 0.12, size.height * 0.25)
      ..cubicTo(
        size.width * 0.34,
        size.height * 0.18,
        size.width * 0.46,
        size.height * 0.48,
        size.width * 0.68,
        size.height * 0.38,
      )
      ..cubicTo(
        size.width * 0.82,
        size.height * 0.32,
        size.width * 0.9,
        size.height * 0.55,
        size.width * 0.78,
        size.height * 0.7,
      );
    canvas.drawPath(path, routePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ItineraryDetailView extends StatelessWidget {
  final int selectedDay;
  final bool isPublic;
  final Function(int) onDayChanged;
  final Function(bool) onPublicChanged;
  final VoidCallback onAddPlaceTap;
  final MapboxMap? mapController;
  final Function(MapboxMap) onMapCreated;
  final bool isMapLoaded;
  final VoidCallback onLoadMapTap;
  final ScrollController scrollController;
  final Map<String, GlobalKey> activityKeys;
  final Function(ItineraryActivityEntity) onActivityTap;
  final Function(ItineraryActivityEntity) onActivityLongPress;
  final Function(ItineraryActivityEntity) onEditActivity;
  final Function(ItineraryActivityEntity) onReplaceActivity;
  final Function(ItineraryActivityEntity) onDeleteActivity;
  final Function(ItineraryActivityEntity) onRateActivity;
  final Function(ItineraryActivityEntity, bool, bool) onEditTime;
  final Function(ItineraryActivityEntity, ItineraryActivityEntity)
  onDirectionTap;
  final VoidCallback onShareTap;
  final VoidCallback onFavoriteTap;
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
    required this.isMapLoaded,
    required this.onLoadMapTap,
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
    required this.onFavoriteTap,
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
                    const Icon(
                      Icons.error_outline,
                      size: AppSizes.s48,
                      color: AppColorsExt.error,
                    ),
                    const SizedBox(height: AppSizes.s16),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: AppSizes.s16),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<ItineraryCubit>().loadData(),
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
            final canReview = _canReviewItinerary(itin);

            return Stack(
              children: [
                // ✅ MAP CHIẾM TOÀN MÀN HÌNH (full-screen, tương tác hoàn toàn)
                Positioned.fill(
                  child: isMapLoaded
                      ? ItineraryMapView(
                          activities: currentDayData.activities,
                          allDays: itin.days,
                          selectedDay: selectedDay,
                          onMarkerTap: onMarkerTap,
                          onMapCreated: onMapCreated,
                        )
                      : _LazyMapPreview(
                          day: currentDayData,
                          onLoadMapTap: onLoadMapTap,
                        ),
                ),

                // ✅ BOTTOM SHEET KÉO LÊN/XUỐNG (DraggableScrollableSheet)
                DraggableScrollableSheet(
                  initialChildSize: 0.45, // Mở 45% màn hình ban đầu
                  minChildSize: 0.12, // Thu nhỏ tối đa → gần như chỉ thấy map
                  maxChildSize: 0.85, // Mở rộng tối đa → che gần hết map
                  snap: true,
                  snapSizes: const [0.12, 0.45, 0.85],
                  builder: (context, sheetScrollController) {
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
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
                                _buildContentCard(
                                  context,
                                  itin,
                                  currentDayData,
                                  itin.days,
                                ),
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
                      _floatingCircleButton(
                        Icons.arrow_back_ios_new,
                        () => Navigator.pop(context),
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
                      if (canReview) ...[
                        _floatingCircleButton(Icons.star_outline_rounded, () {
                          showDialog(
                            context: context,
                            builder: (_) => ItineraryRatingPopup(
                              itineraryId: itin.id,
                              itineraryTitle: itin.title,
                              totalLocations: itin.totalLocations,
                              visitedLocations: itin.visitedLocations,
                            ),
                          );
                        }),
                        const SizedBox(width: AppSizes.s12),
                      ],
                      _floatingCircleButton(
                        isEditMode ? Icons.check_rounded : Icons.edit_outlined,
                        onEditModeTap,
                        active: isEditMode,
                      ),
                      if (!isEditMode) ...[
                        if (itin.isPublic) ...[
                          const SizedBox(width: AppSizes.s12),
                          _floatingCircleButton(
                            itin.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            onFavoriteTap,
                            iconColor: itin.isFavorite
                                ? Colors.redAccent
                                : Colors.white,
                          ),
                        ],
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

  bool _canReviewItinerary(ItineraryDetailEntity itin) {
    final today = DateUtils.dateOnly(DateTime.now());
    final endDate = DateUtils.dateOnly(itin.endDate);
    final status = itin.status.toUpperCase();
    final hasStarted =
        status == 'ONGOING' || status == 'COMPLETED' || itin.trackingActive;

    return today.isAfter(endDate) && hasStarted && itin.visitedLocations > 0;
  }

  Widget _buildContentCard(
    BuildContext context,
    ItineraryDetailEntity itin,
    ItineraryDayEntity currentDayData,
    List<ItineraryDayEntity> displayDays,
  ) {
    final visibleActivities = _timelineActivities(currentDayData);
    final destinationCount = _visitActivities(currentDayData).length;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.r32)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.s20,
        vertical: AppSizes.s12,
      ),
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
                children: displayDays
                    .map<Widget>(
                      (day) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: DaySelectorChip(
                          dayNumber: day.dayNumber,
                          locationCount: day.locationsCount,
                          dateLabel: _formatShortDate(
                            itin.startDate.add(
                              Duration(days: day.dayNumber - 1),
                            ),
                          ),
                          isSelected: selectedDay == day.dayNumber,
                          onTap: () => onDayChanged(day.dayNumber),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.s12),
          Row(
            children: [
              Text(
                '$destinationCount điểm trong ngày',
                style: AppTextStylesExt.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onAddPlaceTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
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
          // ── Theo dõi lịch trình (geofence + dwell) ──────────────────────
          _DayCostSummaryCard(
            day: currentDayData,
            visitActivities: _visitActivities(currentDayData),
            isHotelStart: _isHotelStart,
          ),
          const SizedBox(height: AppSizes.s16),
          TrackingSection(
            itineraryId: itin.id,
            date: currentDayData.date,
            itineraryStatus: itin.status,
            activities: currentDayData.activities,
            showStartButton: false,
            dbTrackingActive: itin.trackingActive,
            onStopped: () => context
                .read<ItineraryCubit>()
                .toggleItineraryStatus(itin.id, false),
          ),
          // Dùng Builder để đọc TrackingCubit (được provide ở ItineraryDetailScreen)
          // và truyền trackingStatus cho từng TimelineActivityCard.
          Builder(
            builder: (context) {
              final tracking = context.watch<TrackingCubit>().state;
              final activities = visibleActivities;
              return Column(
                children: activities.asMap().entries.map((entry) {
                  final index = entry.key;
                  final activity = entry.value;
                  final key = activityKeys.putIfAbsent(
                    activity.id,
                    () => GlobalKey(),
                  );
                  final nextActivity = index < activities.length - 1
                      ? activities[index + 1]
                      : null;
                  final nextTransport = nextActivity == null
                      ? null
                      : (activities[index].transportInfo?.isNotEmpty == true
                            ? activities[index].transportInfo
                            : _estimateTransit(
                                activity.latitude,
                                activity.longitude,
                                nextActivity.latitude,
                                nextActivity.longitude,
                              ));
                  // Lấy trạng thái tracking theo itineraryDetailId (= activity.id)
                  final TrackingPlaceStatus? trackingStatus = tracking.isActive
                      ? tracking.byDetailId(activity.id)
                      : null;
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
                    onStartTimeTap: () => onEditTime(
                      activity,
                      true,
                      index == activities.length - 1,
                    ),
                    onEndTimeTap: () => onEditTime(
                      activity,
                      false,
                      index == activities.length - 1,
                    ),
                    isEditMode: isEditMode,
                    onDirectionTap: nextActivity != null
                        ? () => onDirectionTap(activity, nextActivity)
                        : null,
                    trackingStatus: trackingStatus,
                    onCheckIn: trackingStatus != null
                        ? () => context.read<TrackingCubit>().manualCheckIn(
                            activity.id,
                          )
                        : null,
                    isCheckingIn: tracking.checkingInDetailId == activity.id,
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: AppSizes.s40),
        ],
      ),
    );
  }

  List<ItineraryActivityEntity> _visitActivities(ItineraryDayEntity day) {
    return day.activities
        .where((activity) => !_isHotelStart(activity))
        .toList();
  }

  List<ItineraryActivityEntity> _timelineActivities(ItineraryDayEntity day) {
    if (day.dayNumber == 1) return _visitActivities(day);

    final hotels = day.activities.where(_isHotelStart).toList();
    final visits = _visitActivities(day);
    return [...hotels, ...visits];
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

  String _formatShortDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  // Ước tính thời gian di chuyển từ tọa độ (Haversine + tốc độ 25 km/h)
  static String _estimateTransit(
    double? lat1,
    double? lng1,
    double? lat2,
    double? lng2,
  ) {
    if (lat1 == null || lng1 == null || lat2 == null || lng2 == null) {
      return 'Di chuyển đến điểm tiếp theo';
    }
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final km = r * 2 * atan2(sqrt(a), sqrt(1 - a));
    final mins = (km / 25 * 60).ceil().clamp(1, 999);
    if (mins < 60) return '~$mins phút di chuyển';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '~$h giờ di chuyển' : '~$h giờ $m phút di chuyển';
  }

  Widget _floatingCircleButton(
    IconData icon,
    VoidCallback onTap, {
    bool active = false,
    Color? iconColor,
  }) {
    return Material(
      color: active
          ? AppColors.primary.withAlpha(220)
          : Colors.black.withAlpha(120),
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
