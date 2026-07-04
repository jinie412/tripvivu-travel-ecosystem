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
import 'package:travel_advisor_mobile/features/food/presentation/screens/food_menu_screen.dart';
import 'package:travel_advisor_mobile/features/food/presentation/widgets/pre_order_popup.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_activity_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_day_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/tracking/presentation/cubit/tracking_cubit.dart';
import 'package:travel_advisor_mobile/features/itinerary/tracking/presentation/cubit/tracking_state.dart';
import 'package:travel_advisor_mobile/features/itinerary/tracking/data/models/tracking_models.dart';
import 'package:travel_advisor_mobile/features/itinerary/tracking/presentation/widgets/tracking_section.dart';
import 'package:travel_advisor_mobile/features/itinerary/tracking/tracking_config.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_detail_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/cubit/itinerary_cubit.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/cubit/itinerary_state.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/widgets/day_selector_chip.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/widgets/conflict_resolution_sheet.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/widgets/timeline_activity_card.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/widgets/public_visibility_switch.dart';
import 'package:travel_advisor_mobile/features/place/presentation/cubit/place_detail_cubit.dart';
import 'package:travel_advisor_mobile/features/place/presentation/screens/place_detail_screen.dart';
import 'package:travel_advisor_mobile/features/saved/data/datasources/favorite_remote_datasource.dart';
import 'package:travel_advisor_mobile/features/review/domain/entities/location_review_entity.dart';
import 'package:travel_advisor_mobile/features/review/presentation/cubit/review_cubit.dart';
import 'package:travel_advisor_mobile/features/review/presentation/cubit/review_state.dart';
import 'package:travel_advisor_mobile/features/review/presentation/constants/review_tags.dart'
    show getTagsForCategory;
import 'package:travel_advisor_mobile/features/review/presentation/screens/place_review_screen.dart';
import 'package:travel_advisor_mobile/features/review/presentation/screens/review_catalog_screen.dart';
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
  bool _showPerPersonCost = false;
  ItineraryDetailEntity? _editSnapshot;
  MapboxMap? _mapController;
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _activityKeys = {};
  final Set<String> _openingReviewActivityIds = <String>{};
  String? _highlightedActivityId;

  late final ReviewCubit _sharedReviewCubit;
  Map<String, bool> _hasReviewById = {};
  Map<String, bool> _isVisitedFromBackendById = {};
  bool _reviewStatusLoading = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _sharedReviewCubit = sl<ReviewCubit>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadReviewStatuses();
    });
  }

  void _showAddPlaceScreen() {
    final state = context.read<ItineraryCubit>().state;
    double? refLat;
    double? refLng;
    String? proposedVisitTime;
    List<String> existingIds = [];
    String? destinationCity;

    if (state is ItineraryLoaded && state.selectedItinerary != null) {
      final itin = state.selectedItinerary!;
      destinationCity = itin.destination;
      for (final day in itin.days) {
        for (final act in day.activities) {
          existingIds.add(act.placeId ?? act.id);
        }
      }
      try {
        final dayData = itin.days.firstWhere(
          (d) => d.dayNumber == _selectedDay,
        );
        if (dayData.activities.isNotEmpty) {
          // Dùng tọa độ trung bình của ngày để gợi ý bao phủ toàn khu vực,
          // không bị bias về phía địa điểm cuối ngày
          final validActivities = dayData.activities
              .where((a) => a.latitude != null && a.longitude != null)
              .toList();
          if (validActivities.isNotEmpty) {
            refLat =
                validActivities
                    .map((a) => a.latitude!)
                    .reduce((s, v) => s + v) /
                validActivities.length;
            refLng =
                validActivities
                    .map((a) => a.longitude!)
                    .reduce((s, v) => s + v) /
                validActivities.length;
          }
          proposedVisitTime = dayData.activities.last.endTime;
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
      destinationCity: destinationCity,
      onAdd: (place) async {
        final success = await context.read<ItineraryCubit>().addActivityToDay(
          _selectedDay,
          place.id,
          place.name,
          lat: place.latitude,
          lng: place.longitude,
          imageUrl: place.imageUrl,
          address: place.address,
          category: place.category,
          openHourCompressed: place.openHourCompressed,
        );
        if (!mounted) return;

        if (success != null && success.isFull) {
          _showAddActivityConflictResolutionSheet(
            context,
            place: place,
            canExtend: success.canExtend,
            canReduce: success.canReduceTime,
            canAddDay: success.canAddDay,
          );
          return;
        }

        if (success != null && !success.isFull) {
          _handleSuccessAdd(context, success, place);
          return;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Lịch trình đã kín, không thể thêm địa điểm này. Vui lòng sắp xếp lại hoặc tăng thời gian.',
              ),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
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
        .cast<ItineraryActivityEntity?>()
        .firstWhere((a) => a?.id == activityId, orElse: () => null);
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
    if (placeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy thông tin địa điểm')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => sl<PlaceDetailCubit>(),
          child: PlaceDetailScreen(placeId: placeId, showRelatedPlaces: false),
        ),
      ),
    );
  }

  void _onEditModeTap() async {
    if (_isEditMode) {
      final bool? confirmSave = await showDialog<bool>(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.save_rounded,
                  color: AppColors.primary,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Lưu lịch trình',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Bạn có chắc chắn muốn lưu lại các thay đổi vừa chỉnh sửa không?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Hủy',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Lưu',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      if (confirmSave == true && mounted) {
        await context.read<ItineraryCubit>().confirmUpdateItinerary(
          widget.itineraryId,
        );
        if (!mounted) return;
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
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_rounded,
                color: AppColorsExt.error,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Hủy chỉnh sửa?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Các thay đổi chưa lưu sẽ bị mất. Bạn có chắc muốn hủy không?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Tiếp tục sửa',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColorsExt.error,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Hủy thay đổi',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
            final cubit = context.read<ItineraryCubit>();
            final state = cubit.state;
            if (state is ItineraryLoaded && state.selectedItinerary != null) {
              final itin = state.selectedItinerary!;
              final timeWindow = cubit.resolveTimeWindow(itin);
              final dailyEndMin = toMinutes(timeWindow.endTime);

              final dayData = itin.days.firstWhere(
                (d) => d.dayNumber == _selectedDay,
                orElse: () => ItineraryDayEntity(
                  dayNumber: _selectedDay,
                  date: DateTime.now(),
                  activities: [],
                  totalDuration: '0h',
                  locationsCount: 0,
                  dayBudget: 0.0,
                ),
              );

              if (dayData.activities.isNotEmpty) {
                // Validation: Check if ANY activity violates open/close times after shift
                bool hasViolation = false;
                String violationMsg = '';

                // Lấy ngày hiện tại
                final visitDate = dayData.date;
                final daysMap = [
                  'Monday',
                  'Tuesday',
                  'Wednesday',
                  'Thursday',
                  'Friday',
                  'Saturday',
                  'Sunday',
                ];
                final dayName = daysMap[visitDate.weekday - 1];

                bool isChecking = false;
                for (final act in dayData.activities) {
                  if (act.id == activity.id) isChecking = true;

                  int targetStartMin = toMinutes(act.startTime);
                  int targetEndMin = toMinutes(act.endTime);

                  if (act.id == activity.id) {
                    if (isStart) {
                      targetStartMin += deltaMin;
                      targetEndMin += deltaMin;
                    } else {
                      targetEndMin += deltaMin;
                    }
                  } else if (shouldAdjustSubsequent == true && isChecking) {
                    targetStartMin += deltaMin;
                    targetEndMin += deltaMin;
                  } else {
                    continue;
                  }

                  if (act.openHourCompressed != null &&
                      act.openHourCompressed!.isNotEmpty) {
                    try {
                      final dynamic hours = json.decode(
                        act.openHourCompressed!,
                      );
                      final dynamic slots = hours[dayName];
                      if (slots != null && slots is List && slots.isNotEmpty) {
                        final openStr = slots[0][0]?.toString();
                        final closeStr = slots[0][1]?.toString();
                        if (openStr != null && closeStr != null) {
                          final openMin = toMinutes(openStr.substring(0, 5));
                          final closeMin = toMinutes(closeStr.substring(0, 5));
                          if (targetStartMin < openMin ||
                              targetEndMin > closeMin) {
                            hasViolation = true;
                            violationMsg =
                                'Địa điểm "${act.title}" hoạt động từ ${openStr.substring(0, 5)} - ${closeStr.substring(0, 5)}. Việc chỉnh sửa làm vi phạm giờ mở/đóng cửa của địa điểm này.';
                            break;
                          }
                        }
                      }
                    } catch (_) {}
                  }

                  if (act.id == activity.id && shouldAdjustSubsequent != true)
                    break; // If not adjusting subsequent, only check this one
                }

                if (hasViolation) {
                  bool? confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text(
                        'Cảnh báo vi phạm giờ hoạt động',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      content: Text(
                        '$violationMsg\n\nBạn có chắc chắn muốn tiếp tục chỉnh sửa không?',
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text(
                            'Hủy',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            elevation: 0,
                          ),
                          child: const Text(
                            'Tiếp tục',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirm != true) return;
                }

                final lastActivity = dayData.activities.last;
                final currentLastMin = toMinutes(lastActivity.endTime);
                final newLastMin = shouldAdjustSubsequent == true
                    ? currentLastMin + deltaMin
                    : toMinutes(activity.endTime) + deltaMin;

                if (newLastMin > dailyEndMin) {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => ConflictResolutionSheet(
                      canExtend:
                          newLastMin <=
                          (24 * 60 - 1), // Không cho kéo dài quá 23:59
                      canReduce: true, // Hỗ trợ giảm bằng optimizeDay API
                      canAddDay:
                          false, // Không thêm ngày trong chế độ sửa giờ cục bộ
                      onSelect: (option) async {
                        Navigator.pop(ctx);
                        if (option == 0) return; // Hủy bỏ

                        if (option == 1) {
                          // Kéo dài thời gian
                          final pinResult = cubit.updateActivityTimesWithShift(
                            activityId: activity.id,
                            deltaMinutes: deltaMin,
                            shiftStartTimeOnly: isStart,
                          );
                          if (mounted) {
                            if (pinResult.lunchWasPinned) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Đã cập nhật. Bữa trưa "${pinResult.lunchActivityTitle}" được giữ nguyên trong khung 11:30–13:30.',
                                  ),
                                  backgroundColor: const Color(0xFFF59E0B),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Đã cập nhật và kéo dài thời gian tham quan trong ngày',
                                  ),
                                  backgroundColor: const Color(0xFF10B981),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            }
                          }
                        } else if (option == 2) {
                          // Giảm thời gian
                          // Áp dụng tịnh tiến cục bộ trước để lấy thông số bị lố
                          cubit.updateActivityTimesWithShift(
                            activityId: activity.id,
                            deltaMinutes: deltaMin,
                            shiftStartTimeOnly: isStart,
                          );

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đang tối ưu lại thời gian...'),
                            ),
                          );

                          try {
                            final notes = await cubit.applyOptimizedDay(
                              _selectedDay,
                              true,
                              lockedActivityId: activity.id,
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đã giảm giờ thành công!'),
                                  backgroundColor: Colors.green,
                                ),
                              );

                              if (notes.isNotEmpty) {
                                // Thay thế ID bằng title trong Flutter (dự phòng trường hợp backend chưa mapping)
                                final mappedNotes = notes.map((note) {
                                  String newNote = note;
                                  for (var a in dayData.activities) {
                                    if (newNote.contains(a.id)) {
                                      newNote = newNote.replaceAll(
                                        a.id,
                                        a.title,
                                      );
                                    }
                                  }
                                  return newNote;
                                }).toList();

                                // Đợi một chút để người dùng thấy thông báo SnackBar trước khi hiện Popup
                                await Future.delayed(
                                  const Duration(milliseconds: 600),
                                );
                                if (!mounted) return;

                                showDialog(
                                  context: context,
                                  builder: (ctx) => Dialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.timer_outlined,
                                            color: AppColors.primary,
                                            size: 48,
                                          ),
                                          const SizedBox(height: 16),
                                          const Text(
                                            'Chi tiết giảm giờ',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Flexible(
                                            child: SingleChildScrollView(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: mappedNotes
                                                    .map(
                                                      (n) => Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              bottom: 8.0,
                                                            ),
                                                        child: Row(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            const Text(
                                                              '• ',
                                                              style: TextStyle(
                                                                fontSize: 15,
                                                                color: AppColors
                                                                    .textSecondary,
                                                                height: 1.4,
                                                              ),
                                                            ),
                                                            Expanded(
                                                              child: Text(
                                                                n,
                                                                style: const TextStyle(
                                                                  fontSize: 15,
                                                                  color: AppColors
                                                                      .textSecondary,
                                                                  height: 1.4,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    )
                                                    .toList(),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    AppColors.primary,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 14,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                elevation: 0,
                                              ),
                                              child: const Text(
                                                'Đóng',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            // Revert the local shift because the API failed
                            cubit.updateActivityTimesWithShift(
                              activityId: activity.id,
                              deltaMinutes: -deltaMin,
                              shiftStartTimeOnly: isStart,
                              protectLunchWindow: false,
                            );
                            if (mounted) {
                              final errorMsg = e.toString().replaceAll(
                                'Exception: ',
                                '',
                              );
                              showTimeError('Không thể giảm giờ: $errorMsg');
                            }
                          }
                        }
                      },
                    ),
                  );
                  return; // Chờ người dùng chọn trong Sheet
                }
              }
            }

            final pinResult = cubit.updateActivityTimesWithShift(
              activityId: activity.id,
              deltaMinutes: deltaMin,
              shiftStartTimeOnly: isStart,
            );
            if (mounted && pinResult.lunchWasPinned) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Bữa trưa "${pinResult.lunchActivityTitle}" được giữ nguyên trong khung giờ 11:30–13:30.',
                  ),
                  backgroundColor: const Color(0xFFF59E0B),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }
            return;
          }
        }
      }

      // ── Validate chồng chéo với các địa điểm khác (Cho trường hợp sửa đơn lẻ) ──
      final state = context.read<ItineraryCubit>().state;
      if (state is ItineraryLoaded && state.selectedItinerary != null) {
        try {
          final dayData = state.selectedItinerary!.days.firstWhere(
            (d) => d.dayNumber == _selectedDay,
          );

          final newStartTimeStr = isStart ? newTime : activity.startTime;
          final newEndTimeStr = isStart ? activity.endTime : newTime;
          final newStartMin = toMinutes(newStartTimeStr);
          final newEndMin = toMinutes(newEndTimeStr);

          for (final a in dayData.activities) {
            if (a.id == activity.id) continue;
            final aStartMin = toMinutes(a.startTime);
            final aEndMin = toMinutes(a.endTime);

            // Check overlap: new time interval strictly intersects with activity a's time interval
            if (newStartMin < aEndMin && newEndMin > aStartMin) {
              await showTimeError(
                'Thời gian bạn chọn bị chồng chéo với địa điểm "${a.title}" (${a.startTime} - ${a.endTime}).\n\n'
                'Vui lòng chọn thời gian khác.',
              );
              return;
            }
          }

          // Check open/close for single edit
          if (activity.openHourCompressed != null &&
              activity.openHourCompressed!.isNotEmpty) {
            final daysMap = [
              'Monday',
              'Tuesday',
              'Wednesday',
              'Thursday',
              'Friday',
              'Saturday',
              'Sunday',
            ];
            final dayName = daysMap[dayData.date.weekday - 1];
            final dynamic hours = json.decode(activity.openHourCompressed!);
            final dynamic slots = hours[dayName];
            if (slots != null && slots is List && slots.isNotEmpty) {
              final openStr = slots[0][0]?.toString();
              final closeStr = slots[0][1]?.toString();
              if (openStr != null && closeStr != null) {
                final openMin = toMinutes(openStr.substring(0, 5));
                final closeMin = toMinutes(closeStr.substring(0, 5));
                if (newStartMin < openMin || newEndMin > closeMin) {
                  await showTimeError(
                    'Địa điểm "${activity.title}" hoạt động từ ${openStr.substring(0, 5)} - ${closeStr.substring(0, 5)}.\n\n'
                    'Vui lòng chọn thời gian khác.',
                  );
                  return;
                }
              }
            }
          }
        } catch (_) {}
      }
      // ──────────────────────────────────────────────────────────────────────────

      if (!mounted) return;
      context.read<ItineraryCubit>().updateActivityTimeSingle(
        activity.id,
        startTime: isStart ? newTime : null,
        endTime: isStart ? null : newTime,
      );
    }
  }

  double _calcDistance(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLng / 2) *
            sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  void _onReplaceActivity(ItineraryActivityEntity activity) {
    List<String> existingIds = [];
    String? destinationCity;
    final state = context.read<ItineraryCubit>().state;
    if (state is ItineraryLoaded && state.selectedItinerary != null) {
      destinationCity = state.selectedItinerary!.destination;
      for (final day in state.selectedItinerary!.days) {
        for (final act in day.activities) {
          existingIds.add(act.placeId ?? act.id);
        }
      }
    }

    final capturedDay = _selectedDay;

    ReplacePlaceSheet.show(
      context,
      activity: activity,
      existingIds: existingIds,
      destinationCity: destinationCity,
      onReplace: (place) async {
        final oldLat = activity.latitude;
        final oldLng = activity.longitude;
        final newLat = place.latitude;
        final newLng = place.longitude;

        final successData = await context
            .read<ItineraryCubit>()
            .replaceActivity(
              activity.id,
              place.id,
              place.name,
              newLat: newLat,
              newLng: newLng,
              newImageUrl: place.imageUrl,
              newRating: place.rating,
              newReviewCount: place.reviewCount,
              newAddress: place.address,
              newCategory: place.category,
              autoOptimize:
                  false, // thay thế tại chỗ, tối ưu thứ tự sau nếu cần
            );
        if (!mounted) return;

        if (successData.isFull) {
          _showReplaceActivityConflictResolutionSheet(
            context,
            activity: activity,
            place: place,
            canExtend: successData.canExtend,
            canReduce: successData.canReduceTime,
          );
          return;
        }

        if (successData.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã thay thế bằng "${place.name}"'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );

          // Kiểm tra khoảng cách để gợi ý tối ưu lại thứ tự lịch trình
          bool shouldSuggestOptimize = false;
          if (newLat == null || newLng == null) {
            // Không có tọa độ (VD: từ danh mục yêu thích) → nên hỏi vì không biết xa gần
            shouldSuggestOptimize = true;
          } else if (oldLat != null && oldLng != null) {
            shouldSuggestOptimize =
                _calcDistance(oldLat, oldLng, newLat, newLng) > 15.0;
          }

          if (shouldSuggestOptimize && mounted) {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    Icon(
                      Icons.route_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Sắp xếp lại lịch trình?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                content: const Text(
                  'Địa điểm vừa chọn khá xa so với vị trí ban đầu. Bạn có muốn sắp xếp lại thứ tự các địa điểm trong ngày để tuyến đường hợp lý hơn không?',
                  style: TextStyle(height: 1.5, fontSize: 14),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text(
                      'Giữ nguyên',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Sắp xếp lại',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );

            if (confirm == true && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đang tối ưu lại lịch trình...')),
              );
              try {
                await context.read<ItineraryCubit>().applyOptimizedDay(
                  capturedDay,
                  false,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Đã sắp xếp lại lịch trình!'),
                      backgroundColor: const Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              } catch (_) {}
            }
          }

          // Đợi một chút để UI render xong card mới, sau đó cuộn và highlight
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              _scrollToActivity(activity.id);
            }
          });
        }
      },
    );
  }

  Future<void> _onRateActivity(ItineraryActivityEntity activity) async {
    if (_openingReviewActivityIds.contains(activity.id)) return;
    setState(() => _openingReviewActivityIds.add(activity.id));

    try {
      // Nếu địa điểm đã có review → mở màn hình xem (read-only)
      if (_hasReviewById[activity.id] == true) {
        await openReviewedPlaceReview(
          context,
          itineraryId: widget.itineraryId,
          itineraryDetailId: activity.id,
        );
        return;
      }

      // Viết review mới — dùng shared cubit đã preload
      if (_sharedReviewCubit.state is! ReviewLoaded) {
        await _sharedReviewCubit.loadReviewData(widget.itineraryId);
      }
      if (!mounted) return;

      final state = _sharedReviewCubit.state;
      if (state is! ReviewLoaded) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể mở dữ liệu đánh giá'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Lấy categoryId từ detail đã load để hiển thị tag đúng danh mục
      final categoryId = state.itinerary.locations
          .where((l) => l.id == activity.id)
          .firstOrNull
          ?.categoryId;

      if (!state.itinerary.locations.any((loc) => loc.id == activity.id)) {
        _sharedReviewCubit.ensureLocationAvailable(
          LocationReviewEntity(
            id: activity.id,
            placeId: activity.placeId,
            name: activity.title,
            imageUrl: activity.imageUrl,
            day: _selectedDay,
            isVisited: true,
          ),
        );
      }

      final submitted = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => PlaceReviewScreen(
            locationId: activity.id,
            reviewCubit: _sharedReviewCubit,
            submitOnSave: true,
            itineraryId: widget.itineraryId,
            reviewTags: getTagsForCategory(categoryId),
          ),
        ),
      );

      if (submitted == true) {
        if (!mounted) return;
        setState(() => _hasReviewById[activity.id] = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu đánh giá địa điểm'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể mở giao diện đánh giá'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted)
        setState(() => _openingReviewActivityIds.remove(activity.id));
    }
  }

  void _onDeleteActivity(ItineraryActivityEntity activity) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColorsExt.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColorsExt.error,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Xóa địa điểm',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Bạn có chắc chắn muốn xóa "${activity.title}" khỏi lịch trình không?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: const Text(
                        'Hủy',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(dialogContext);
                        final success = await context
                            .read<ItineraryCubit>()
                            .deleteActivity(activity.id);
                        if (!mounted) return;
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Đã xóa ${activity.title}'),
                              backgroundColor: const Color(
                                0xFF10B981,
                              ), // Green success color
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Xóa địa điểm thất bại. Vui lòng thử lại.',
                              ),
                              backgroundColor: AppColorsExt.error,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColorsExt.error,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Xóa',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showShareSheet() {
    final invitedUsers = <String>{};
    final searchController = TextEditingController();
    var searchQuery = '';
    final users = <({String id, String name, String email, String avatar})>[
      (
        id: 'a',
        name: 'Nguyễn Văn A',
        email: 'anv@example.com',
        avatar: 'https://i.pravatar.cc/150?u=a',
      ),
      (
        id: 'b',
        name: 'Trần Thị B',
        email: 'btt@example.com',
        avatar: 'https://i.pravatar.cc/150?u=b',
      ),
      (
        id: 'c',
        name: 'Lê Văn C',
        email: 'clv@example.com',
        avatar: 'https://i.pravatar.cc/150?u=c',
      ),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final normalizedQuery = searchQuery.trim().toLowerCase();
          final filteredUsers = normalizedQuery.isEmpty
              ? users
              : users.where((user) {
                  return user.name.toLowerCase().contains(normalizedQuery) ||
                      user.email.toLowerCase().contains(normalizedQuery);
                }).toList();

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
                  controller: searchController,
                  onChanged: (value) =>
                      setModalState(() => searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm qua tên hoặc email...',
                    prefixIcon: const Icon(Icons.search, size: AppSizes.iconMd),
                    suffixIcon: searchQuery.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              searchController.clear();
                              setModalState(() => searchQuery = '');
                            },
                          ),
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
                  child: filteredUsers.isEmpty
                      ? Center(
                          child: Text(
                            'Không tìm thấy người dùng phù hợp',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      : ListView(
                          children: filteredUsers
                              .map(
                                (user) => _shareUserItem(
                                  user.name,
                                  user.email,
                                  user.avatar,
                                  invitedUsers.contains(user.id),
                                  () => setModalState(
                                    () => invitedUsers.add(user.id),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    ).whenComplete(searchController.dispose);
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
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white,
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
                color: Colors.white,
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
    _sharedReviewCubit.close();
    super.dispose();
  }

  Future<void> _loadReviewStatuses() async {
    if (_reviewStatusLoading) return;
    _reviewStatusLoading = true;
    try {
      await _sharedReviewCubit.loadReviewData(widget.itineraryId);
      if (!mounted) return;
      final state = _sharedReviewCubit.state;
      if (state is ReviewLoaded) {
        final hasReviewMap = <String, bool>{};
        final isVisitedMap = <String, bool>{};
        for (final loc in state.itinerary.locations) {
          hasReviewMap[loc.id] = loc.hasReview;
          isVisitedMap[loc.id] = loc.isVisited;
        }
        setState(() {
          _hasReviewById = hasReviewMap;
          _isVisitedFromBackendById = isVisitedMap;
        });
      }
    } catch (_) {
      // Non-fatal: buttons fall back to default state
    } finally {
      _reviewStatusLoading = false;
    }
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

  Future<void> _onRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      await context.read<ItineraryCubit>().refreshDetail(widget.itineraryId);
      if (mounted) await _loadReviewStatuses();
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  void _handleSuccessAdd(
    BuildContext context,
    dynamic success,
    dynamic place, {
    bool extendTime = false,
  }) {
    final addedDayNumber = success.dayNumber as int?;
    final newActivityId = success.activityId as String?;
    final originalDay = _selectedDay;

    if (addedDayNumber != null && addedDayNumber != originalDay) {
      setState(() {
        _selectedDay = addedDayNumber;
      });

      // Thông báo rõ ràng khi địa điểm được thêm vào ngày khác với ngày đang xem
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.r16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Đã chuyển sang ngày khác',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            'Ngày $originalDay đã đủ lịch.\n\n'
            '"${place.name}" đã được thêm vào Ngày $addedDayNumber.',
            style: const TextStyle(height: 1.5, fontSize: 14),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.r8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Đã hiểu',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            extendTime
                ? 'Đã thêm "${place.name}" và kéo dài thời gian tham quan trong ngày'
                : 'Đã thêm "${place.name}" vào Ngày $addedDayNumber',
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && newActivityId != null) {
        _scrollToActivity(newActivityId);
      }
    });
  }

  void _showAddActivityConflictResolutionSheet(
    BuildContext context, {
    required dynamic place,
    required bool canExtend,
    required bool canReduce,
    required bool canAddDay,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ConflictResolutionSheet(
        canExtend: canExtend,
        canReduce: canReduce,
        canAddDay: canAddDay,
        onSelect: (option) async {
          Navigator.pop(ctx);
          if (option == 0) return; // Hủy bỏ

          bool extendTime = option == 1;
          bool allowReduceTime = option == 2;
          bool addExtraDay = option == 3;

          final retrySuccess = await context
              .read<ItineraryCubit>()
              .addActivityToDay(
                _selectedDay,
                place.id,
                place.name,
                lat: place.latitude,
                lng: place.longitude,
                imageUrl: place.imageUrl,
                address: place.address,
                category: place.category,
                openHourCompressed: place.openHourCompressed,
                allowReduceTime: allowReduceTime,
                extendTime: extendTime,
                addExtraDay: addExtraDay,
              );

          if (!mounted) return;

          if (retrySuccess != null && !retrySuccess.isFull) {
            _handleSuccessAdd(
              context,
              retrySuccess,
              place,
              extendTime: extendTime,
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Vẫn không thể thêm địa điểm này sau khi điều chỉnh.',
                ),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  void _showReplaceActivityConflictResolutionSheet(
    BuildContext context, {
    required ItineraryActivityEntity activity,
    required dynamic place,
    required bool canExtend,
    required bool canReduce,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ConflictResolutionSheet(
        canExtend: canExtend,
        canReduce: canReduce,
        canAddDay: false,
        onSelect: (option) async {
          Navigator.pop(ctx);
          if (option == 0) return;

          bool extendTime = option == 1;
          bool allowReduceTime = option == 2;

          final successData = await context
              .read<ItineraryCubit>()
              .replaceActivity(
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
                autoOptimize: false,
                allowReduceTime: allowReduceTime,
                extendTime: extendTime,
              );

          if (!mounted) return;

          if (successData.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  extendTime
                      ? 'Đã thay thế bằng "${place.name}" và kéo dài thời gian tham quan trong ngày'
                      : 'Đã thay thế bằng "${place.name}"',
                ),
                backgroundColor: const Color(
                  0xFF10B981,
                ), // AppColorsExt.success
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );

            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                _scrollToActivity(activity.id);
              }
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Vẫn không thể thay thế địa điểm này sau khi điều chỉnh.',
                ),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        },
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
            openingReviewActivityIds: _openingReviewActivityIds,
            reviewHasReviewById: _hasReviewById,
            reviewIsVisitedById: _isVisitedFromBackendById,
            onEditTime: _onEditTime,
            onDirectionTap: _launchDirections,
            onShareTap: _showShareSheet,
            onFavoriteTap: _toggleItineraryFavorite,
            onMarkerTap: (id) => _scrollToActivity(id),
            highlightedActivityId: _highlightedActivityId,
            isEditMode: _isEditMode,
            onEditModeTap: _onEditModeTap,
            onDiscardTap: _onDiscardChanges,
            isRefreshing: _isRefreshing,
            onRefreshTap: _onRefresh,
            showPerPersonCost: _showPerPersonCost,
            onCostScopeChanged: (value) {
              setState(() => _showPerPersonCost = value);
            },
          ),
        ),
      ),
    );
  }

  void _showFoodProximityPopup(BuildContext ctx, TrackingState state) {
    if (ModalRoute.of(ctx)?.isCurrent != true) return;
    final name = state.nearbyRestaurantName ?? 'Quán ăn gần đây';
    final detailId = state.nearbyRestaurantDetailId ?? '';
    final placeId = state.nearbyRestaurantPlaceId ?? '';
    if (!ctx.read<TrackingCubit>().claimNearbyRestaurantPopup(detailId)) {
      return;
    }
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
              builder: (_) => FoodMenuScreen(
                placeId: placeId,
                restaurantName: name,
                itineraryDetailId: detailId,
              ),
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
  final Map<String, bool> visitedByBackend;
  final int participantCount;
  final bool showPerPersonCost;
  final ValueChanged<bool> onCostScopeChanged;

  const _DayCostSummaryCard({
    required this.day,
    required this.visitActivities,
    required this.isHotelStart,
    this.visitedByBackend = const {},
    required this.participantCount,
    required this.showPerPersonCost,
    required this.onCostScopeChanged,
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
    final selfDriveCost = day.activities.fold<double>(
      0,
      (sum, activity) => sum + activity.transportCost,
    );
    final visitedCount = visitActivities
        .where(
          (activity) =>
              activity.status == ActivityStatus.daDi ||
              (visitedByBackend[activity.id] ?? false),
        )
        .length;
    final totalCost = placeCost + hotelCost + selfDriveCost;

    final people = participantCount.clamp(1, 999);
    double displayCost(double value) =>
        showPerPersonCost ? value / people : value;
    String money(double value) =>
        '${formatter.format(displayCost(value))} ${day.currency}';

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
              Expanded(
                child: Text(
                  showPerPersonCost
                      ? 'Chi ph\u00ed trong ng\u00e0y / 1 ng\u01b0\u1eddi'
                      : 'T\u1ed5ng chi ph\u00ed trong ng\u00e0y / $people ng\u01b0\u1eddi',
                  style: const TextStyle(
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
          const SizedBox(height: 10),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('T\u1ed5ng nh\u00f3m')),
              ButtonSegment(value: true, label: Text('1 ng\u01b0\u1eddi')),
            ],
            selected: {showPerPersonCost},
            showSelectedIcon: false,
            onSelectionChanged: (selection) {
              onCostScopeChanged(selection.first);
            },
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
          category.contains('luu tru') ||
          category.contains('khách sạn') ||
          category.contains('khach san') ||
          category.contains('hotel') ||
          title.contains('hotel') ||
          title.contains('khách sạn') ||
          title.contains('khach san');
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
              opacity: 0.22,
              child: CustomPaint(painter: _MapPreviewGridPainter()),
            ),
          ),
          Positioned(
            left: 22,
            right: 22,
            top: MediaQuery.of(context).padding.top + 88,
            child: Container(
              height: 118,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.36),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white.withValues(alpha: 0.62)),
              ),
              child: const Center(
                child: Icon(
                  Icons.map_outlined,
                  size: 42,
                  color: Color(0xFF93C5FD),
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            top: MediaQuery.of(context).padding.top + 220,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(22),
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
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.route_rounded,
                      color: Color(0xFF2563EB),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ngày ${day.dayNumber} • $pointCount điểm / Xem chi tiết hành trình trên bản đồ.',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: onLoadMapTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Xem',
                      style: TextStyle(fontWeight: FontWeight.w900),
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
  final Set<String> openingReviewActivityIds;
  final Map<String, bool> reviewHasReviewById;
  final Map<String, bool> reviewIsVisitedById;
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
  final bool isRefreshing;
  final VoidCallback onRefreshTap;
  final bool showPerPersonCost;
  final ValueChanged<bool> onCostScopeChanged;

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
    required this.openingReviewActivityIds,
    required this.reviewHasReviewById,
    required this.reviewIsVisitedById,
    required this.onEditTime,
    required this.onDirectionTap,
    required this.onShareTap,
    required this.onFavoriteTap,
    required this.onMarkerTap,
    this.highlightedActivityId,
    required this.isEditMode,
    required this.onEditModeTap,
    required this.onDiscardTap,
    required this.isRefreshing,
    required this.onRefreshTap,
    required this.showPerPersonCost,
    required this.onCostScopeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: BlocBuilder<ItineraryCubit, ItineraryState>(
        builder: (context, state) {
          if (state is ItineraryLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  if (state.message != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      state.message!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            );
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
            // Guard: nếu days rỗng, không thể render → hiển thị thông báo
            if (itin.days.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 64,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Lịch trình chưa có ngày nào',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Dữ liệu đang được xử lý. Vui lòng thử lại sau.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: onRefreshTap,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Tải lại'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            final isFuture = DateTime.now().isBefore(itin.startDate);
            final currentDayData = itin.days.firstWhere(
              (d) => d.dayNumber == selectedDay,
              orElse: () => itin.days.first,
            );

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
                          // Thanh kéo (drag handle) + nút refresh
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 4),
                            child: Row(
                              children: [
                                const SizedBox(width: 48),
                                Expanded(
                                  child: Center(
                                    child: Container(
                                      width: 40,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 48,
                                  child: isRefreshing
                                      ? const Center(
                                          child: SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        )
                                      : IconButton(
                                          icon: const Icon(
                                            Icons.refresh_rounded,
                                            size: 20,
                                          ),
                                          padding: EdgeInsets.zero,
                                          onPressed: onRefreshTap,
                                          color: AppColors.textSecondary,
                                        ),
                                ),
                              ],
                            ),
                          ),
                          // Nội dung cuộn được
                          Expanded(
                            child: ListView(
                              controller: sheetScrollController,
                              padding: EdgeInsets.zero,
                              physics: const AlwaysScrollableScrollPhysics(),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _floatingCircleButton(
                        Icons.arrow_back_ios_new,
                        () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PublicVisibilitySwitch(
                            value: itin.isPublic,
                            dark: true,
                            borderless: true,
                            onChanged: (value) =>
                                _confirmVisibilityChange(context, itin, value),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isFuture) ...[
                                if (isEditMode) ...[
                                  _floatingCircleButton(
                                    Icons.close_rounded,
                                    onDiscardTap,
                                    iconColor: const Color(0xFFEF4444),
                                  ),
                                  const SizedBox(width: AppSizes.s12),
                                ],
                                _floatingCircleButton(
                                  isEditMode
                                      ? Icons.check_rounded
                                      : Icons.edit_outlined,
                                  onEditModeTap,
                                  active: isEditMode,
                                ),
                              ],
                              if (!isEditMode) ...[
                                if (itin.isPublic) ...[
                                  if (isFuture)
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
                                if (isFuture || itin.isPublic)
                                  const SizedBox(width: AppSizes.s12),
                                _floatingCircleButton(
                                  Icons.share_outlined,
                                  onShareTap,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
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

  Future<void> _confirmVisibilityChange(
    BuildContext context,
    ItineraryDetailEntity itin,
    bool nextValue,
  ) async {
    if (nextValue == itin.isPublic) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          nextValue ? 'Công khai lịch trình?' : 'Chuyển về riêng tư?',
        ),
        content: Text(
          nextValue
              ? 'Lịch trình sẽ hiển thị trong khu vực khám phá công khai.'
              : 'Người khác sẽ không còn thấy lịch trình này trong khu vực công khai.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await context.read<ItineraryCubit>().toggleVisibility(itin.id, nextValue);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextValue
                ? 'Đã công khai lịch trình'
                : 'Đã chuyển lịch trình về riêng tư',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể cập nhật trạng thái công khai'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
          const SizedBox(height: AppSizes.s8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: displayDays
                  .map<Widget>(
                    (day) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: DaySelectorChip(
                        dayNumber: day.dayNumber,
                        locationCount: day.locationsCount,
                        dateLabel: _formatShortDate(
                          itin.startDate.add(Duration(days: day.dayNumber - 1)),
                        ),
                        isSelected: selectedDay == day.dayNumber,
                        onTap: () => onDayChanged(day.dayNumber),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '$destinationCount điểm trong ngày',
                style: AppTextStylesExt.bodyMedium.copyWith(
                  color: const Color(0xFF0F172A),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (isEditMode)
                GestureDetector(
                  onTap: onAddPlaceTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.accent],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.24),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, size: 16, color: Colors.white),
                        SizedBox(width: 5),
                        Text(
                          'Thêm địa điểm',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.s16),
          _DayCostSummaryCard(
            day: currentDayData,
            visitActivities: _visitActivities(currentDayData),
            isHotelStart: _isHotelStart,
            visitedByBackend: reviewIsVisitedById,
            participantCount: itin.participantCount,
            showPerPersonCost: showPerPersonCost,
            onCostScopeChanged: onCostScopeChanged,
          ),
          const SizedBox(height: AppSizes.s16),
          TrackingSection(
            itineraryId: itin.id,
            date: currentDayData.date,
            itineraryStatus: itin.status,
            activities: currentDayData.activities,
            showStartButton: false,
            dbTrackingActive: itin.trackingActive,
            onStopped: () {
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final endPlusOne = DateTime(
                itin.endDate.year,
                itin.endDate.month,
                itin.endDate.day,
              ).add(const Duration(days: 1));
              context.read<ItineraryCubit>().toggleItineraryStatus(
                itin.id,
                false,
                stoppedStatus: !today.isBefore(endPlusOne)
                    ? ItineraryStatus.completed
                    : ItineraryStatus.uncompleted,
              );
            },
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
                    participantCount: itin.participantCount,
                    showPerPersonCost: showPerPersonCost,
                    onAddTap: onAddPlaceTap,
                    onEditTap: () => onEditActivity(activity),
                    onReplaceTap: () => onReplaceActivity(activity),
                    onDeleteTap: () => onDeleteActivity(activity),
                    onRateTap: () => onRateActivity(
                      trackingStatus?.status == VisitStatus.visited
                          ? activity.copyWith(status: ActivityStatus.daDi)
                          : activity,
                    ),
                    isOpeningReview: openingReviewActivityIds.contains(
                      activity.id,
                    ),
                    onCardTap: () => onActivityTap(activity),
                    onCardLongPress: () => onActivityLongPress(activity),
                    onViewDetailTap: () => onActivityLongPress(activity),
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
                    hasReview: reviewHasReviewById[activity.id],
                    backendIsVisited: reviewIsVisitedById[activity.id] ?? false,
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
    return day.activities;
  }

  bool _isHotelStart(ItineraryActivityEntity activity) {
    final category = (activity.category ?? '').toLowerCase();
    final title = activity.title.toLowerCase();
    return category.contains('lưu trú') ||
        category.contains('luu tru') ||
        category.contains('khách sạn') ||
        category.contains('khach san') ||
        category.contains('hotel') ||
        title.contains('hotel') ||
        title.contains('khách sạn') ||
        title.contains('khach san');
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
    if (mins < 60) return '$mins phút di chuyển';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '$h giờ di chuyển' : '$h giờ $m phút di chuyển';
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
