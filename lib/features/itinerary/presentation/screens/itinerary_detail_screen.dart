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
import 'package:travel_advisor_mobile/core/constants/cost_ui_labels.dart';
import 'package:travel_advisor_mobile/core/constants/app_text_styles.dart';
import 'package:travel_advisor_mobile/core/di/injection_container.dart';
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
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/incurred_cost_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/repositories/itinerary_repository.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/cubit/itinerary_cubit.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/cubit/itinerary_state.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/screens/incurred_costs_screen.dart';
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
import 'package:travel_advisor_mobile/features/itinerary/domain/utils/day_cost_calculator.dart';

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
  bool _isSavingChanges = false;
  bool _isMapLoaded = false;
  ItineraryDetailEntity? _editSnapshot;
  MapboxMap? _mapController;
  final ScrollController _scrollController = ScrollController();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  final Map<String, GlobalKey> _activityKeys = {};
  final Set<String> _openingReviewActivityIds = <String>{};
  String? _highlightedActivityId;

  late final ReviewCubit _sharedReviewCubit;
  Map<String, bool> _hasReviewById = {};
  Map<String, bool> _isVisitedFromBackendById = {};
  bool _reviewStatusLoading = false;
  bool _isRefreshing = false;

  /// Tổng chi phí phát sinh (mục 1.6) theo từng place_id — chỉ hiển thị bên
  /// cạnh giá, không có hành động thêm/sửa ở màn này (xem "Quản lý chi phí"
  /// ở tổng quan lịch trình). Chỉ gồm chi phí AD-HOC (không phải baseline) —
  /// dòng "Chi phí kế hoạch" tách riêng ở _baselineCostsByPlace vì per-adult,
  /// cần nhân số người khi cộng tổng ngày (xem _DayStatsCard).
  Map<String, double> _costsByPlace = {};
  // Dòng "Chi phí kế hoạch" (tự động khi check-in) theo place_id — per-adult,
  // KHÔNG cộng chung với _costsByPlace để tránh nhân sai (ad-hoc là số tuyệt
  // đối, baseline là per-adult cần nhân adultCount/childCount×childPriceRatio).
  Map<String, double> _baselineCostsByPlace = {};
  // Chi phí phát sinh KHÔNG gắn địa điểm nhưng có chọn ngày (vd "Chi phí
  // khác" ghi trực tiếp theo ngày) — cộng vào "Tổng quan ngày" bên cạnh
  // tổng theo địa điểm ở trên, để con số ngày đầy đủ hơn.
  Map<int, double> _extraCostsByDay = {};

  ItineraryDetailEntity? get _currentItinerary {
    final state = context.read<ItineraryCubit>().state;
    if (state is ItineraryLoaded) return state.selectedItinerary;
    return widget.initialDetail;
  }

  bool get _isOwnerViewer => _currentItinerary?.isOwner == true;

  @override
  void initState() {
    super.initState();
    _sharedReviewCubit = sl<ReviewCubit>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadReviewStatuses();
    });
    _loadCostsByPlace();
  }

  /// Chỉ để hiển thị badge "+chi phí" bên cạnh giá và "++ phát sinh" ở
  /// "Tổng quan ngày" — lỗi ở đây không được làm hỏng màn hình chi tiết
  /// lịch trình.
  Future<void> _loadCostsByPlace() async {
    try {
      final costs = await sl<ItineraryRepository>().getIncurredCosts(
        widget.itineraryId,
      );
      if (!mounted) return;
      final byPlace = <String, double>{};
      final baselineByPlace = <String, double>{};
      final byDay = <int, double>{};
      for (final cost in costs) {
        final placeId = cost.placeId;
        final dayNumber = cost.dayNumber;
        if (placeId != null && placeId.isNotEmpty) {
          // "Chi phí kế hoạch" là per-adult (cần nhân số người khi cộng tổng
          // ngày) — tách riêng khỏi ad-hoc (số tuyệt đối, không nhân).
          if (cost.type == CostType.baselinePlan) {
            baselineByPlace[placeId] =
                (baselineByPlace[placeId] ?? 0) + cost.amount;
          } else {
            byPlace[placeId] = (byPlace[placeId] ?? 0) + cost.amount;
          }
        } else if (dayNumber != null) {
          // Chi phí không gắn địa điểm nhưng có chọn ngày (vd "Chi phí
          // khác" ghi trực tiếp theo ngày) — cộng thẳng vào tổng ngày đó,
          // KHÔNG cộng vào badge theo địa điểm (placeId null).
          byDay[dayNumber] = (byDay[dayNumber] ?? 0) + cost.amount;
        }
      }
      setState(() {
        _costsByPlace = byPlace;
        _baselineCostsByPlace = baselineByPlace;
        _extraCostsByDay = byDay;
      });
    } catch (_) {
      // Bỏ qua — badge chi phí phát sinh chỉ là hiển thị phụ.
    }
  }

  void _showAddPlaceScreen() {
    if (!_isOwnerViewer) return;

    final cubit = context.read<ItineraryCubit>();
    final state = cubit.state;
    double? refLat;
    double? refLng;
    String? proposedVisitTime;
    List<String> existingIds = [];
    String? destinationCity;
    String? itineraryId;
    bool hasCapacity = true;

    if (state is ItineraryLoaded && state.selectedItinerary != null) {
      final itin = state.selectedItinerary!;
      destinationCity = itin.destination;
      itineraryId = itin.id;
      hasCapacity = cubit.hasCapacityForNewActivity(itin);
      for (final day in itin.days) {
        for (final act in day.activities) {
          final String id = act.placeId ?? act.id;
          if (id.isNotEmpty) {
            existingIds.add(id);
          }
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
      itineraryId: itineraryId,
      hasCapacity: hasCapacity,
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
          price: place.estimatedCost,
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
          _handleSuccessAdd(
            context,
            success,
            place,
            reorderNotes: success.reorderNotes,
          );
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
        travelMode: _currentItinerary?.travelMode ?? 'DRIVING',
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
          child: PlaceDetailScreen(placeId: placeId, showRelatedPlaces: true),
        ),
      ),
    );
  }

  void _onEditModeTap() async {
    if (!_isOwnerViewer || _isSavingChanges) return;

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
        setState(() => _isSavingChanges = true);
        try {
          final saveResult = await context
              .read<ItineraryCubit>()
              .confirmUpdateItinerary(widget.itineraryId);
          if (!mounted) return;
          if (!saveResult.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  saveResult.error ??
                      'Không thể lưu lịch trình. Vui lòng thử lại.',
                ),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.r12),
                ),
              ),
            );
            return;
          }
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
        } finally {
          if (mounted) {
            setState(() => _isSavingChanges = false);
          }
        }
      }
    } else {
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
    if (!_isOwnerViewer) return;

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
      final selectedDayStillExists =
          snapshot?.days.any((day) => day.dayNumber == _selectedDay) ?? true;
      setState(() {
        _isEditMode = false;
        _editSnapshot = null;
        if (!selectedDayStillExists && snapshot!.days.isNotEmpty) {
          _selectedDay = snapshot.days.last.dayNumber;
        }
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

  String? _shiftOpeningHoursViolation({
    required ItineraryDayEntity day,
    required String editedActivityId,
    required int deltaMinutes,
    required bool isStartTimeEdit,
  }) {
    const dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    int toMinutes(String value) {
      final parts = value.substring(0, 5).split(':');
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    }

    String toTime(int minutes) {
      final normalized = minutes.clamp(0, 24 * 60 - 1);
      final hour = normalized ~/ 60;
      final minute = normalized % 60;
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    }

    var isAffected = false;
    final dayName = dayNames[day.date.weekday - 1];
    for (final activity in day.activities) {
      if (activity.id == editedActivityId) isAffected = true;
      if (!isAffected) continue;

      if (activity.startTime == activity.endTime) continue;

      var targetStart = toMinutes(activity.startTime);
      var targetEnd = toMinutes(activity.endTime);
      if (activity.id == editedActivityId) {
        if (isStartTimeEdit) {
          targetStart += deltaMinutes;
          targetEnd += deltaMinutes;
        } else {
          targetEnd += deltaMinutes;
        }
      } else {
        targetStart += deltaMinutes;
        targetEnd += deltaMinutes;
      }

      final compressed = activity.openHourCompressed;
      if (compressed == null || compressed.isEmpty) continue;
      try {
        final Map<String, dynamic> hours = jsonDecode(compressed);
        final rawSlots = hours[dayName];
        if (rawSlots is! List || rawSlots.isEmpty) {
          return 'Địa điểm "${activity.title}" không hoạt động trong ngày này.';
        }

        final validSlots = <String>[];
        var fitsAnySlot = false;
        for (final rawSlot in rawSlots) {
          if (rawSlot is! List || rawSlot.length < 2) continue;
          final open = rawSlot[0]?.toString();
          final close = rawSlot[1]?.toString();
          if (open == null ||
              close == null ||
              open.length < 5 ||
              close.length < 5) {
            continue;
          }
          final openLabel = open.substring(0, 5);
          final closeLabel = close.substring(0, 5);
          validSlots.add('$openLabel - $closeLabel');
          // "00:00" làm giờ đóng cửa nghĩa là nửa đêm (24:00), không phải
          // đầu ngày — nếu để nguyên 0 phút thì mọi khung giờ đều bị coi là
          // không hợp lệ.
          final rawCloseMinutes = toMinutes(closeLabel);
          final closeMinutes = rawCloseMinutes == 0 ? 24 * 60 : rawCloseMinutes;
          if (targetStart >= toMinutes(openLabel) &&
              targetEnd <= closeMinutes) {
            fitsAnySlot = true;
            break;
          }
        }

        if (!fitsAnySlot && validSlots.isNotEmpty) {
          return 'Tịnh tiến sẽ xếp "${activity.title}" vào '
              '${toTime(targetStart)} - ${toTime(targetEnd)}, trong khi địa điểm '
              'chỉ hoạt động ${validSlots.join(', ')}.';
        }
      } catch (_) {}
    }
    return null;
  }

  void _onEditActivity(ItineraryActivityEntity activity) {
    if (!_isOwnerViewer) return;

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
    if (!_isOwnerViewer) return;

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

      final proposedStartTime = isStart ? newTime : activity.startTime;
      final itineraryCubit = context.read<ItineraryCubit>();
      if (itineraryCubit.isLunchActivity(activity) &&
          !itineraryCubit.isWithinLunchWindow(proposedStartTime)) {
        await showTimeError(
          'Giờ đến địa điểm ăn trưa phải nằm trong khung 10:30 - 14:00.',
        );
        return;
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
            // "00:00" làm giờ đóng cửa nghĩa là nửa đêm (cuối ngày, tức 24:00),
            // không phải đầu ngày — nếu để nguyên 0 phút thì mọi giờ trong
            // ngày đều bị coi là "vượt quá giờ đóng cửa".
            final rawCloseMin = toM(slot.$2);
            final closeMin = rawCloseMin == 0 ? 24 * 60 : rawCloseMin;
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

        var canOfferShift = false;
        if (hasSubsequent) {
          final previewState = itineraryCubit.state;
          if (previewState is ItineraryLoaded &&
              previewState.selectedItinerary != null) {
            final previewDay = previewState.selectedItinerary!.days.firstWhere(
              (day) => day.dayNumber == _selectedDay,
            );
            final openingViolation = _shiftOpeningHoursViolation(
              day: previewDay,
              editedActivityId: activity.id,
              deltaMinutes: deltaMin,
              isStartTimeEdit: isStart,
            );
            canOfferShift = openingViolation == null;
          }
        }

        if (canOfferShift) {
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
                          final rawCloseMin = toMinutes(
                            closeStr.substring(0, 5),
                          );
                          final closeMin = rawCloseMin == 0
                              ? 24 * 60
                              : rawCloseMin;
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
                  int? confirm = await showDialog<int>(
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
                        '$violationMsg\n\nBạn muốn sắp xếp lại lịch trình để không vi phạm không?',
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, 0),
                          child: const Text(
                            'Hủy',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, 1),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            elevation: 0,
                          ),
                          child: const Text(
                            'Sắp xếp lại',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirm == null || confirm == 0) return;
                  if (confirm == 1) {
                    if (mounted) {
                      cubit.updateActivityTimesWithShift(
                        activityId: activity.id,
                        deltaMinutes: deltaMin,
                        shiftStartTimeOnly: isStart,
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đang tối ưu lại lịch trình...'),
                          duration: Duration(seconds: 1),
                        ),
                      );

                      final optimizeResult = await cubit.optimizeEditedDay(
                        dayNumber: _selectedDay,
                        editedActivityId: activity.id,
                      );

                      if (optimizeResult.error != null && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(optimizeResult.error!),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        cubit.discardChanges(itin);
                      } else if (mounted &&
                          optimizeResult.reorderNotes.isNotEmpty) {
                        _showReduceTimeNotesDialog(
                          context,
                          optimizeResult.reorderNotes,
                        );
                      }
                    }
                    return;
                  }
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
                              await _handleLunchPinnedOptimization(
                                cubit,
                                pinResult.lunchActivityId!,
                                pinResult.lunchActivityTitle ?? 'Ăn trưa',
                                itin,
                                triggerActivityId: activity.id,
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
                          final pinResult = cubit.updateActivityTimesWithShift(
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
                              lockedActivityId: pinResult.lunchWasPinned
                                  ? null
                                  : activity.id,
                              pinnedLunchActivityId: pinResult.lunchWasPinned
                                  ? pinResult.lunchActivityId
                                  : null,
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

                                _showOptimizationNotes(context, mappedNotes);
                              }
                            }
                          } catch (e) {
                            cubit.discardChanges(itin);
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

            final snapshotState = cubit.state;
            if (snapshotState is! ItineraryLoaded ||
                snapshotState.selectedItinerary == null) {
              return;
            }
            final shiftSnapshot = snapshotState.selectedItinerary!;
            final pinResult = cubit.updateActivityTimesWithShift(
              activityId: activity.id,
              deltaMinutes: deltaMin,
              shiftStartTimeOnly: isStart,
            );
            if (mounted && pinResult.lunchWasPinned) {
              await _handleLunchPinnedOptimization(
                cubit,
                pinResult.lunchActivityId!,
                pinResult.lunchActivityTitle ?? 'Ăn trưa',
                shiftSnapshot,
                triggerActivityId: activity.id,
              );
            }
            return;
          }
        }
      }

      // ── Validate chồng chéo với các địa điểm khác (Cho trường hợp sửa đơn lẻ) ──
      final state = itineraryCubit.state;
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
                final rawCloseMin = toMinutes(closeStr.substring(0, 5));
                final closeMin = rawCloseMin == 0 ? 24 * 60 : rawCloseMin;
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

  void _showOptimizationNotes(BuildContext context, List<String> mappedNotes) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                'Chi tiết tối ưu',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: mappedNotes
                        .map(
                          (n) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '• ',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    n,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: AppColors.textSecondary,
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
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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

  Future<void> _handleLunchPinnedOptimization(
    ItineraryCubit cubit,
    String pinnedLunchActivityId,
    String lunchTitle,
    ItineraryDetailEntity snapshot, {
    required String triggerActivityId,
  }) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã đụng giờ ăn trưa "$lunchTitle". Đang tự động tối ưu lại lịch trình...',
        ),
        backgroundColor: const Color(0xFFF59E0B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    try {
      final directlyEditingLunch = triggerActivityId == pinnedLunchActivityId;
      final notes = await cubit.applyOptimizedDay(
        _selectedDay,
        true,
        // Ưu tiên tuyệt đối thay đổi của người dùng. Khi một activity phía
        // trước bị kéo dài, giữ nguyên activity đó và cho phép optimizer dời
        // quán ăn trong khung 10:30-14:00, thay vì rút ngắn activity vừa sửa.
        lockedActivityId: triggerActivityId,
        pinnedLunchActivityId: directlyEditingLunch
            ? pinnedLunchActivityId
            : null,
      );
      if (mounted && notes.isNotEmpty) {
        final state = cubit.state;
        if (state is ItineraryLoaded && state.selectedItinerary != null) {
          final dayData = state.selectedItinerary!.days.firstWhere(
            (d) => d.dayNumber == _selectedDay,
          );
          final mappedNotes = notes.map((note) {
            String newNote = note;
            for (var a in dayData.activities) {
              if (newNote.contains(a.id)) {
                newNote = newNote.replaceAll(a.id, a.title);
              }
            }
            return newNote;
          }).toList();

          await Future.delayed(const Duration(milliseconds: 600));
          if (!mounted) return;
          _showOptimizationNotes(context, mappedNotes);
        }
      }
    } catch (error, stackTrace) {
      debugPrint('Lunch-window optimization failed: $error\n$stackTrace');
      cubit.discardChanges(snapshot);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Không thể sắp xếp lịch trình'),
          content: Text(
            'Không thể áp dụng thay đổi mà vẫn giữ bữa trưa "$lunchTitle" trong khung 10:30 - 14:00. '
            'Lịch trình đã được khôi phục. Vui lòng chọn giờ khác hoặc giảm thời gian tham quan.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
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
    if (!_isOwnerViewer) return;

    List<String> existingIds = [];
    String? destinationCity;
    String? itineraryId;
    final state = context.read<ItineraryCubit>().state;
    if (state is ItineraryLoaded && state.selectedItinerary != null) {
      destinationCity = state.selectedItinerary!.destination;
      itineraryId = state.selectedItinerary!.id;
      for (final day in state.selectedItinerary!.days) {
        for (final act in day.activities) {
          final String id = act.placeId ?? act.id;
          if (id.isNotEmpty) {
            existingIds.add(id);
          }
        }
      }
    }

    ReplacePlaceSheet.show(
      context,
      activity: activity,
      existingIds: existingIds,
      destinationCity: destinationCity,
      itineraryId: itineraryId,
      onReplace: (place) async {
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
              autoOptimize: true,
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
    if (!_isOwnerViewer) return;
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
    if (!_isOwnerViewer) return;

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

  @override
  void dispose() {
    _scrollController.dispose();
    _sheetController.dispose();
    _sharedReviewCubit.close();
    super.dispose();
  }

  Future<void> _loadReviewStatuses() async {
    if (!_isOwnerViewer) return;
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
    if (!_isOwnerViewer) return;

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
      final itineraryCubit = context.read<ItineraryCubit>();
      final trackingCubit = context.read<TrackingCubit>();

      await itineraryCubit.refreshDetail(widget.itineraryId);
      if (!mounted) return;

      // Đồng bộ tracking với dữ liệu DB vừa tải:
      // - DB đang theo dõi nhưng cubit mất phiên (app khởi động lại...) →
      //   khôi phục để thanh tracking + marker hoạt động trở lại.
      // - DB đã dừng (kết thúc ngày, dừng từ màn khác...) → dọn phiên stale
      //   để thanh tracking không hiển thị sai.
      final itinState = itineraryCubit.state;
      final freshDetail = itinState is ItineraryLoaded
          ? itinState.selectedItinerary
          : null;
      if (freshDetail != null && freshDetail.id == widget.itineraryId) {
        if (freshDetail.trackingActive && !trackingCubit.state.isActive) {
          await trackingCubit.restoreIfActive();
        } else {
          await trackingCubit.notifyDbState(
            widget.itineraryId,
            freshDetail.trackingActive,
          );
        }
      }

      // Đang theo dõi lịch trình này → tải lại trạng thái đã ghé ngay,
      // không chờ chu kỳ refresh 30 giây của tracking.
      if (mounted &&
          trackingCubit.state.isActive &&
          trackingCubit.state.itineraryId == widget.itineraryId) {
        await trackingCubit.refreshStatus();
      }

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
    List<String> reorderNotes = const [],
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
      ).then((_) {
        if (mounted) _showReduceTimeNotesDialog(this.context, reorderNotes);
      });
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

      if (reorderNotes.isNotEmpty) {
        // Đợi snackbar bắt đầu hiện rồi mới hiện dialog, tránh chồng UI ngay lập tức
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) _showReduceTimeNotesDialog(this.context, reorderNotes);
        });
      }
    }

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && newActivityId != null) {
        _scrollToActivity(newActivityId);
      }
    });
  }

  /// Hiển thị dialog liệt kê các thay đổi (giảm giờ tham quan, dời giờ...)
  /// mà AI optimizer đã tự động thực hiện khi người dùng chọn "Giảm giờ".
  void _showReduceTimeNotesDialog(BuildContext context, List<String> notes) {
    if (notes.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.r16),
        ),
        title: Row(
          children: [
            Icon(Icons.timer_outlined, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Đã điều chỉnh thời gian',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: notes
                .map(
                  (note) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.circle,
                            size: 6,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            note,
                            style: const TextStyle(fontSize: 13, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
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
  }

  void _showAddActivityConflictResolutionSheet(
    BuildContext context, {
    required dynamic place,
    required bool canExtend,
    required bool canReduce,
    required bool canAddDay,
    String? errorMessage,
  }) {
    if (!canExtend && !canReduce && !canAddDay) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Không có phương án nào có thể thêm địa điểm này mà vẫn bảo đảm thời gian và giờ mở cửa.',
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.r12),
          ),
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ConflictResolutionSheet(
        canExtend: canExtend,
        canReduce: canReduce,
        canAddDay: canAddDay,
        errorMessage: errorMessage,
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
                price: place.estimatedCost,
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
              reorderNotes: retrySuccess.reorderNotes,
            );
          } else {
            _showAddActivityConflictResolutionSheet(
              context,
              place: place,
              canExtend: retrySuccess?.canExtend ?? false,
              canReduce: retrySuccess?.canReduceTime ?? false,
              canAddDay: retrySuccess?.canAddDay ?? false,
              errorMessage:
                  'Vẫn không thể thêm sau khi điều chỉnh. Lý do: Thời gian đóng/mở cửa không khớp, hoặc lịch trình vẫn quá kín. Hãy thử phương án khác bên dưới.',
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
                autoOptimize: true,
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
          body: Stack(
            children: [
              _ItineraryDetailView(
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
                sheetController: _sheetController,
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
                onFavoriteTap: _toggleItineraryFavorite,
                onMarkerTap: (id) => _scrollToActivity(id),
                highlightedActivityId: _highlightedActivityId,
                isEditMode: _isEditMode,
                isSavingChanges: _isSavingChanges,
                onEditModeTap: _onEditModeTap,
                onDiscardTap: _onDiscardChanges,
                isRefreshing: _isRefreshing,
                onRefreshTap: _onRefresh,
                costsByPlace: _costsByPlace,
                baselineCostsByPlace: _baselineCostsByPlace,
                extraCostsByDay: _extraCostsByDay,
              ),
              if (_isSavingChanges)
                Container(
                  color: AppColors.surface,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 16),
                        Text(
                          'Đang lưu lịch trình...',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
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
          ctx.read<TrackingCubit>().dismissNearbyRestaurant(detailId: detailId);
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
          ctx.read<TrackingCubit>().dismissNearbyRestaurant(detailId: detailId);
        },
      ),
    ).then((_) {
      // Đóng popup → dismiss để không hiện lại ngay
      if (ctx.mounted) {
        ctx.read<TrackingCubit>().dismissNearbyRestaurant(
          detailId: detailId,
          evaluateNext: true,
        );
      }
    });
  }
}

/// Card "Tiến độ tham quan" trong ngày — thay cho dòng "x/z đã đi" trong box
/// chi phí và thanh "Đã đi X/Y địa điểm" cũ.
///
/// Trạng thái "đã đi" gộp từ 3 nguồn nên luôn đúng cả khi refresh lẫn khi
/// tracking cập nhật realtime: `activity.status` (chi tiết lịch trình sau
/// refresh), `visitedByBackend` (geofence_visits) và tracking state trong RAM
/// (qua `context.watch<TrackingCubit>`).
class _DayVisitProgressCard extends StatelessWidget {
  final List<ItineraryActivityEntity> visitActivities;
  final Map<String, bool> visitedByBackend;

  const _DayVisitProgressCard({
    required this.visitActivities,
    this.visitedByBackend = const {},
  });

  @override
  Widget build(BuildContext context) {
    final tracking = context.watch<TrackingCubit>().state;
    bool isVisited(ItineraryActivityEntity activity) {
      if (activity.status == ActivityStatus.daDi) return true;
      if (visitedByBackend[activity.id] ?? false) return true;
      return tracking.isActive &&
          tracking.byDetailId(activity.id)?.status == VisitStatus.visited;
    }

    final total = visitActivities.length;
    if (total == 0) return const SizedBox.shrink();

    final visited = visitActivities.where(isVisited).length;
    final progress = (visited / total).clamp(0.0, 1.0);
    final isDone = visited >= total;
    final accent = isDone ? const Color(0xFF10B981) : const Color(0xFF0E9E87);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSizes.s12),
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
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  isDone
                      ? Icons.celebration_rounded
                      : Icons.where_to_vote_rounded,
                  size: 18,
                  color: accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tiến độ tham quan',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isDone
                          ? 'Đã ghé hết địa điểm trong ngày 🎉'
                          : 'Đã đi $visited/$total địa điểm trong ngày',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$visited/$total',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
              tween: Tween(begin: 0, end: progress),
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cảnh báo "ít/không có quán ăn" mà backend tự ghi vào `notes` của hoạt
/// động ĐẦU TIÊN trong ngày (xem annotateDaysMissingRestaurant() —
/// itinerary.service.ts) — chỉ đọc lại và hiển thị, không tự tính gì thêm ở
/// mobile. Rỗng khi ngày đó có đủ ≥2 quán ăn.
class _RestaurantWarningBanner extends StatelessWidget {
  final ItineraryDayEntity day;

  const _RestaurantWarningBanner({required this.day});

  @override
  Widget build(BuildContext context) {
    // KHÔNG dùng day.activities.first nữa — từ ngày 2 trở đi, khách sạn
    // được getItineraryDetail() chèn vào ĐẦU mảng activities (xem
    // itinerary.service.ts), nên "first" thường là dòng khách sạn
    // (notes luôn null), che mất note thật đã ghi đúng ở hoạt động đầu
    // tiên THẬT SỰ. Quét cả ngày, lấy note không rỗng đầu tiên gặp được —
    // chỉ đúng 1 hoạt động/ngày mang note này nên không sợ nhầm.
    String? note;
    for (final activity in day.activities) {
      final candidate = activity.notes;
      if (candidate != null && candidate.trim().isNotEmpty) {
        note = candidate;
        break;
      }
    }
    if (note == null || note.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.s12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.restaurant_outlined,
              size: 18,
              color: Color(0xFFB45309),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                note,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFFB45309),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thay thế _DayCostSummaryCard + _HotelCostCard cũ (2 card riêng, khá rối)
/// bằng 1 card duy nhất kiểu icon-stat, đồng bộ với card ngày ở màn tổng
/// quan lịch trình (ShortItineraryItem) — km di chuyển, giờ tham quan, số
/// địa điểm, giờ di chuyển, tổng chi phí ngày đó (cả nhóm, không gồm khách
/// sạn — khách sạn đã hiển thị đủ ở màn tổng quan, tránh lặp/rối).
class _DayStatsCard extends StatelessWidget {
  final ItineraryDayEntity day;
  final ItineraryDetailEntity itin;
  // Chi phí phát sinh AD-HOC (không phải "Chi phí kế hoạch") theo địa điểm —
  // đã là số tuyệt đối thật sự đã chi, KHÔNG nhân theo số người.
  final Map<String, double> costsByPlace;
  // Dòng "Chi phí kế hoạch" (tự động khi check-in) theo địa điểm — per-adult,
  // PHẢI nhân theo adultCount/childCount×childPriceRatio trước khi cộng vào
  // "Đã chi", khác costsByPlace ở trên.
  final Map<String, double> baselineByPlace;
  // Chi phí phát sinh không gắn địa điểm nhưng có chọn ngày — cộng thêm vào
  // cùng tổng "Đã chi" ở trên cho đủ, cũng là số tuyệt đối không nhân.
  final Map<int, double> extraCostsByDay;

  const _DayStatsCard({
    required this.day,
    required this.itin,
    this.costsByPlace = const {},
    this.baselineByPlace = const {},
    this.extraCostsByDay = const {},
  });

  static String? _hoursText(int minutes) {
    if (minutes <= 0) return null;
    final hours = minutes / 60;
    return hours.toStringAsFixed(hours.truncateToDouble() == hours ? 0 : 1);
  }

  Widget _statItem(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final breakdown = DayCostCalculator.computeDaily(
      day: day,
      adultCount: itin.adultCount,
      childCount: itin.childCount,
      childPriceRatio: itin.childPriceRatio,
    );
    final stats = DayCostCalculator.travelStats(day);
    final locationCount = DayCostCalculator.visitActivities(day).length;
    final formatter = NumberFormat('#,###', 'vi_VN');
    // "Chi phí kế hoạch" (baseline) là per-adult — phải nhân theo số người
    // như breakdown.total ở trên (DayCostCalculator.computeDaily) để 2 con
    // số không lệch ý nghĩa. Ad-hoc (costsByPlace/extraCostsByDay) đã là số
    // tuyệt đối thật sự đã chi, KHÔNG nhân thêm.
    final baselineRaw = day.activities.fold<double>(
      0,
      (sum, a) =>
          sum + (a.placeId != null ? (baselineByPlace[a.placeId] ?? 0) : 0),
    );
    final baselineGroupTotal =
        baselineRaw * itin.adultCount +
        baselineRaw * itin.childPriceRatio * itin.childCount;
    final adhocTotal =
        day.activities.fold<double>(
          0,
          (sum, a) =>
              sum + (a.placeId != null ? (costsByPlace[a.placeId] ?? 0) : 0),
        ) +
        (extraCostsByDay[day.dayNumber] ?? 0);
    final dayIncurredTotal = baselineGroupTotal + adhocTotal;
    final sightseeingText = _hoursText(stats.sightseeingMinutes);
    final travelText = _hoursText(stats.travelMinutes);

    // Hàng trên: địa điểm + giờ tham quan. Hàng dưới: km + giờ di chuyển.
    // 4 chỉ số gộp thành 1 cột dọc duy nhất (thay vì 2 hàng Wrap trước đây).
    final statColumn = <Widget>[
      _statItem(
        Icons.place_rounded,
        '$locationCount địa điểm',
        const Color(0xFFF59E0B),
      ),
      if (sightseeingText != null)
        _statItem(
          Icons.camera_alt_outlined,
          '$sightseeingText giờ tham quan',
          const Color(0xFF10B981),
        ),
      if (stats.distanceKm > 0)
        _statItem(
          Icons.route_rounded,
          '${stats.distanceKm.toStringAsFixed(1)} km',
          const Color(0xFF2563EB),
        ),
      if (travelText != null)
        _statItem(
          Icons.directions_car_filled_outlined,
          '$travelText giờ di chuyển',
          const Color(0xFF8B5CF6),
        ),
    ];

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cột trái: tiêu đề + icon sổ, rồi 4 chỉ số xếp dọc.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tổng quan ngày',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.costText,
                  ),
                ),
                const SizedBox(height: 10),
                ...statColumn
                    .expand((w) => [w, const SizedBox(height: 8)])
                    .take(statColumn.isEmpty ? 0 : statColumn.length * 2 - 1),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Cột phải: Tổng chi phí + Đã chi. Icon sổ chi tiêu đặt ngay cạnh
          // "Tổng chi phí" (chỗ ghi giá tiền) thay vì ở tiêu đề bên trái —
          // đồng bộ vị trí/màu với "Sổ chi tiêu" ở Tổng quan lịch trình
          // (itinerary_summary_screen.dart).
          // Flexible (not a bare Column) so a long amount/currency string
          // can shrink instead of overflowing the Row by a fraction of a
          // pixel on narrower screens or larger accessibility text scales.
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${formatter.format(breakdown.total)} ${day.currency}',
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.costMint,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => IncurredCostsScreen(
                            itineraryId: itin.id,
                            members: itin.members,
                            isCompleted:
                                itin.status.toUpperCase() == 'COMPLETED',
                            initialDayNumber: day.dayNumber,
                            days: itin.days,
                          ),
                        ),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.menu_book_rounded,
                          size: 16,
                          color: AppColors.costHeroEnd,
                        ),
                      ),
                    ),
                  ],
                ),
                const Text(
                  CostUiLabels.dayTotalCost,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: AppColors.costTextMuted,
                  ),
                ),
                if (dayIncurredTotal > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${formatter.format(dayIncurredTotal)} ${day.currency}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.costAmber,
                    ),
                  ),
                  const Text(
                    CostUiLabels.daySpent,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: AppColors.costTextMuted,
                    ),
                  ),
                ],
              ],
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
  final DraggableScrollableController sheetController;
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
  final VoidCallback onFavoriteTap;
  final Function(String) onMarkerTap;
  final String? highlightedActivityId;
  final bool isEditMode;
  final bool isSavingChanges;
  final VoidCallback onEditModeTap;
  final VoidCallback onDiscardTap;
  final bool isRefreshing;
  final VoidCallback onRefreshTap;
  final Map<String, double> costsByPlace;
  final Map<String, double> baselineCostsByPlace;
  final Map<int, double> extraCostsByDay;

  // Kept in sync with the DraggableScrollableSheet's own min/max/snapSizes
  // below — the manual drag handler needs the same numbers.
  static const double _sheetMinSize = 0.12;
  static const double _sheetMaxSize = 0.85;
  static const List<double> _sheetSnapSizes = [0.12, 0.45, 0.85];

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
    required this.sheetController,
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
    required this.onFavoriteTap,
    required this.onMarkerTap,
    this.highlightedActivityId,
    required this.isEditMode,
    required this.isSavingChanges,
    required this.onEditModeTap,
    required this.onDiscardTap,
    required this.isRefreshing,
    required this.onRefreshTap,
    this.costsByPlace = const {},
    this.baselineCostsByPlace = const {},
    this.extraCostsByDay = const {},
  });

  // The handle sits above the sheet's own scrollable content, so it never
  // receives the sheet's built-in drag-to-resize gesture — drive the
  // controller manually from a GestureDetector wrapped around it instead.
  void _onSheetHandleDragUpdate(
    DragUpdateDetails details,
    BuildContext context,
  ) {
    final screenHeight = MediaQuery.of(context).size.height;
    if (screenHeight <= 0 || !sheetController.isAttached) return;
    final delta = details.primaryDelta! / screenHeight;
    final newSize = (sheetController.size - delta).clamp(
      _sheetMinSize,
      _sheetMaxSize,
    );
    sheetController.jumpTo(newSize);
  }

  void _onSheetHandleDragEnd(DragEndDetails details) {
    if (!sheetController.isAttached) return;
    final current = sheetController.size;
    final nearest = _sheetSnapSizes.reduce(
      (a, b) => (current - a).abs() < (current - b).abs() ? a : b,
    );
    sheetController.animateTo(
      nearest,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.premiumBackground,
      body: BlocBuilder<ItineraryCubit, ItineraryState>(
        builder: (context, state) {
          if (state is ItineraryLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
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
                          travelMode: itin.travelMode,
                        )
                      : _LazyMapPreview(
                          day: currentDayData,
                          onLoadMapTap: onLoadMapTap,
                        ),
                ),

                // ✅ BOTTOM SHEET KÉO LÊN/XUỐNG (DraggableScrollableSheet)
                DraggableScrollableSheet(
                  controller: sheetController,
                  initialChildSize: 0.45, // Mở 45% màn hình ban đầu
                  minChildSize:
                      _sheetMinSize, // Thu nhỏ tối đa → gần như chỉ thấy map
                  maxChildSize:
                      _sheetMaxSize, // Mở rộng tối đa → che gần hết map
                  snap: true,
                  snapSizes: _sheetSnapSizes,
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
                          GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onVerticalDragUpdate: (details) =>
                                _onSheetHandleDragUpdate(details, context),
                            onVerticalDragEnd: _onSheetHandleDragEnd,
                            child: Padding(
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
                                          color: AppColors.premiumBorder,
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
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
                                            color: AppColors.premiumMuted,
                                          ),
                                  ),
                                ],
                              ),
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
                          // Member được chia sẻ chỉ có quyền xem: ẩn switch
                          // công khai, nút chỉnh sửa và nút chia sẻ.
                          if (itin.isOwner)
                            PublicVisibilitySwitch(
                              value: itin.isPublic,
                              dark: true,
                              borderless: true,
                              onChanged: (value) => _confirmVisibilityChange(
                                context,
                                itin,
                                value,
                              ),
                            ),
                          if (itin.isOwner) const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isFuture && itin.isOwner) ...[
                                if (isEditMode) ...[
                                  _floatingCircleButton(
                                    Icons.close_rounded,
                                    isSavingChanges ? null : onDiscardTap,
                                    iconColor: const Color(0xFFEF4444),
                                  ),
                                  const SizedBox(width: AppSizes.s12),
                                ],
                                _floatingCircleButton(
                                  isEditMode
                                      ? Icons.check_rounded
                                      : Icons.edit_outlined,
                                  isSavingChanges ? null : onEditModeTap,
                                  active: isEditMode,
                                ),
                              ],
                              if (!isEditMode) ...[
                                if (itin.isPublic) ...[
                                  if (isFuture && itin.isOwner)
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
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
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
          // Số địa điểm trong ngày đã hiện trong _DayStatsCard bên dưới rồi
          // — bỏ dòng "N điểm trong ngày" ở đây để khỏi lặp lại.
          if (isEditMode) ...[
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 10,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
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
                          Icon(
                            Icons.add_location_alt_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
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
            ),
          ],
          const SizedBox(height: AppSizes.s16),
          _DayStatsCard(
            day: currentDayData,
            itin: itin,
            costsByPlace: costsByPlace,
            baselineByPlace: baselineCostsByPlace,
            extraCostsByDay: extraCostsByDay,
          ),
          _RestaurantWarningBanner(day: currentDayData),
          const SizedBox(height: AppSizes.s12),
          _DayVisitProgressCard(
            visitActivities: _visitActivities(currentDayData),
            visitedByBackend: reviewIsVisitedById,
          ),
          const SizedBox(height: AppSizes.s4),
          if (itin.isOwner)
            TrackingSection(
              itineraryId: itin.id,
              date: currentDayData.date,
              itineraryStatus: itin.status,
              activities: currentDayData.activities,
              showStartButton: false,
              dbTrackingActive: itin.trackingActive,
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
                  final TrackingPlaceStatus? trackingStatus =
                      itin.isOwner && tracking.isActive
                      ? tracking.byDetailId(activity.id)
                      : null;
                  return TimelineActivityCard(
                    key: key,
                    activity: activity,
                    day: selectedDay,
                    isFirst: index == 0,
                    isLast: index == activities.length - 1,
                    nextTransportInfo: nextTransport,
                    nextIsHotel:
                        nextActivity != null && _isHotelStart(nextActivity),
                    extraCost: activity.placeId != null
                        ? costsByPlace[activity.placeId]
                        : null,
                    onExtraCostTap: activity.placeId != null
                        ? () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => IncurredCostsScreen(
                                itineraryId: itin.id,
                                members: itin.members,
                                isCompleted:
                                    itin.status.toUpperCase() == 'COMPLETED',
                                initialPlaceId: activity.placeId,
                                initialPlaceName: activity.title,
                                days: itin.days,
                              ),
                            ),
                          )
                        : null,
                    onAddTap: itin.isOwner ? onAddPlaceTap : null,
                    onEditTap: itin.isOwner
                        ? () => onEditActivity(activity)
                        : null,
                    onReplaceTap: itin.isOwner
                        ? () => onReplaceActivity(activity)
                        : null,
                    onDeleteTap: itin.isOwner
                        ? () => onDeleteActivity(activity)
                        : null,
                    onRateTap: itin.isOwner
                        ? () => onRateActivity(
                            trackingStatus?.status == VisitStatus.visited
                                ? activity.copyWith(status: ActivityStatus.daDi)
                                : activity,
                          )
                        : null,
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
                    isEditMode: itin.isOwner && isEditMode,
                    onDirectionTap: nextActivity != null
                        ? () => onDirectionTap(activity, nextActivity)
                        : null,
                    trackingStatus: trackingStatus,
                    canReview: itin.isOwner,
                    onCheckIn: itin.isOwner && trackingStatus != null
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
    VoidCallback? onTap, {
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
