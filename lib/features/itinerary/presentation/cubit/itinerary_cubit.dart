import 'dart:async';
import 'dart:math' as math;
import 'itinerary_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_activity_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_day_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_detail_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_summary.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/repositories/itinerary_repository.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/usecases/itinerary_usecases.dart';
import 'package:travel_advisor_mobile/core/config/app_config.dart';
import 'package:travel_advisor_mobile/features/itinerary/data/datasources/optimize_route_api.dart';

class ItineraryCubit extends Cubit<ItineraryState> {
  final GetItinerariesUseCase _getItineraries;
  final GetItinerarySummaryUseCase _getSummary;
  final DeleteItineraryUseCase _deleteItinerary;
  final GetItineraryDetailUseCase _getItineraryDetail;
  final UpdateItineraryActivitiesUseCase _updateActivities;
  final UpdateItineraryTitleUseCase _updateTitle;
  final ToggleVisibilityUseCase _toggleVisibility;
  final ShareItineraryUseCase _shareItinerary;
  final SearchItineraryShareRecipientsUseCase _searchShareRecipients;
  final CreateItineraryShareLinkUseCase _createShareLink;
  final DeleteActivityUseCase _deleteActivity;
  final OptimizeDayUseCase? optimizeDayUseCase;

  // Khung giờ ăn trưa (đồng bộ với backend Python LUNCH_START / LUNCH_END)
  static const int _kLunchWindowStartMin = 11 * 60 + 30; // 11:30
  static const int _kLunchWindowEndMin = 13 * 60 + 30; // 13:30

  ItineraryStatus? _currentFilter;
  CompletedFilter _currentCompletedFilter = CompletedFilter.all;
  Timer? _searchDebounce;
  String _currentSearchQuery = '';
  int _loadGeneration = 0;

  ItineraryCubit({
    required GetItinerariesUseCase getItineraries,
    required GetItinerarySummaryUseCase getSummary,
    required DeleteItineraryUseCase deleteItinerary,
    required GetItineraryDetailUseCase getItineraryDetail,
    required UpdateItineraryActivitiesUseCase updateActivities,
    required UpdateItineraryTitleUseCase updateTitle,
    required ToggleVisibilityUseCase toggleVisibility,
    required ShareItineraryUseCase shareItinerary,
    required SearchItineraryShareRecipientsUseCase searchShareRecipients,
    required CreateItineraryShareLinkUseCase createShareLink,
    required DeleteActivityUseCase deleteActivity,
    this.optimizeDayUseCase,
  }) : _getItineraries = getItineraries,
       _getSummary = getSummary,
       _deleteItinerary = deleteItinerary,
       _getItineraryDetail = getItineraryDetail,
       _updateActivities = updateActivities,
       _updateTitle = updateTitle,
       _toggleVisibility = toggleVisibility,
       _shareItinerary = shareItinerary,
       _searchShareRecipients = searchShareRecipients,
       _createShareLink = createShareLink,
       _deleteActivity = deleteActivity,
       super(const ItineraryInitial());

  static const bool kDemoMode = AppConfig.kUseMockData;

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }

  Future<void> toggleVisibility(String id, bool isPublic) async {
    final currentState = state;
    if (currentState is! ItineraryLoaded) return;

    if (!kDemoMode) {
      await _toggleVisibility(id, isPublic);
    }

    final selected = currentState.selectedItinerary;
    emit(
      currentState.copyWith(
        selectedItinerary: selected?.id == id
            ? selected!.copyWith(isPublic: isPublic)
            : selected,
      ),
    );
  }

  Future<void> shareItinerary(String id, String recipient) {
    return _shareItinerary(id, recipient);
  }

  Future<List<ItineraryShareRecipient>> searchShareRecipients(String query) {
    return _searchShareRecipients(query);
  }

  Future<ItineraryShareLink> createShareLink(String id) {
    return _createShareLink(id);
  }

  Future<void> loadData({bool keepCurrentList = false}) async {
    final generation = ++_loadGeneration;
    final previousSelected = state is ItineraryLoaded
        ? (state as ItineraryLoaded).selectedItinerary
        : null;
    final previousLoaded = state is ItineraryLoaded
        ? state as ItineraryLoaded
        : null;

    if (keepCurrentList && previousLoaded != null) {
      emit(
        previousLoaded.copyWith(
          searchQuery: _currentSearchQuery,
          isSearching: true,
        ),
      );
    } else {
      emit(const ItineraryLoading());
    }

    try {
      final hasSearch = _currentSearchQuery.isNotEmpty;
      final List<ItineraryEntity> itinerariesResult;
      final ItinerarySummary summaryResult;

      if (hasSearch && previousLoaded != null) {
        itinerariesResult = await _getItineraries(
          status: _currentFilter,
          query: _currentSearchQuery,
        );
        summaryResult = previousLoaded.summary;
      } else {
        final results = await Future.wait([
          _getItineraries(
            status: _currentFilter,
            query: hasSearch ? _currentSearchQuery : null,
          ),
          _getSummary(),
        ]);
        itinerariesResult = results[0] as List<ItineraryEntity>;
        summaryResult = results[1] as ItinerarySummary;
      }

      if (generation != _loadGeneration) return;

      var itineraries = itinerariesResult;

      if (_currentFilter == ItineraryStatus.completed) {
        if (_currentCompletedFilter == CompletedFilter.rated) {
          itineraries = itineraries.where((i) => i.rating != null).toList();
        } else if (_currentCompletedFilter == CompletedFilter.unrated) {
          itineraries = itineraries.where((i) => i.rating == null).toList();
        }
      }

      emit(
        ItineraryLoaded(
          itineraries: itineraries,
          summary: summaryResult,
          activeFilter: _currentFilter,
          activeCompletedFilter: _currentCompletedFilter,
          selectedItinerary: previousSelected,
          searchQuery: _currentSearchQuery,
          isSearching: false,
        ),
      );
    } catch (e) {
      if (kDemoMode) {
        final mockSummary = const ItinerarySummary(
          total: 5,
          draft: 2,
          upcoming: 1,
          ongoing: 1,
          completed: 1,
        );
        final mockItineraries = [
          ItineraryEntity(
            id: 'mock_saigon',
            title: 'Vi vu ở Sài Gòn',
            startDate: DateTime(2026, 5, 8),
            endDate: DateTime(2026, 5, 10),
            status: ItineraryStatus.upcoming,
            progress: 0.0,
            estimatedCost: 6800000,
            visitedLocations: 0,
            totalLocations: 27,
          ),
          ItineraryEntity(
            id: 'mock_completed',
            title: 'Khám phá Đà Nẵng 3 ngày 2 đêm',
            startDate: DateTime.now().subtract(const Duration(days: 10)),
            endDate: DateTime.now().subtract(const Duration(days: 5)),
            status: ItineraryStatus.completed,
            progress: 1.0,
            estimatedCost: 4500000,
            rating: null,
            visitedLocations: 8,
            totalLocations: 8,
          ),
          ItineraryEntity(
            id: 'mock_ongoing',
            title: 'Hè rực rỡ tại Phú Quốc',
            startDate: DateTime.now().subtract(const Duration(days: 1)),
            endDate: DateTime.now().add(const Duration(days: 3)),
            status: ItineraryStatus.ongoing,
            progress: 0.8,
            estimatedCost: 8500000,
            visitedLocations: 10,
            totalLocations: 12,
          ),
        ];
        emit(
          ItineraryLoaded(
            itineraries: mockItineraries,
            summary: mockSummary,
            activeFilter: _currentFilter,
            activeCompletedFilter: _currentCompletedFilter,
            selectedItinerary: (state is ItineraryLoaded)
                ? (state as ItineraryLoaded).selectedItinerary
                : null,
            searchQuery: _currentSearchQuery,
            isSearching: false,
          ),
        );
      } else {
        emit(ItineraryError(e.toString()));
      }
    }
  }

  Future<void> filterBy(ItineraryStatus? status) async {
    _currentFilter = status;
    _currentCompletedFilter = CompletedFilter.all;
    await loadData();
  }

  Future<void> filterByCompleted(CompletedFilter filter) async {
    _currentCompletedFilter = filter;
    await loadData();
  }

  void searchByTitle(String value) {
    final query = value.trim();
    if (query != _currentSearchQuery) {
      _loadGeneration++;
    }
    if (state is ItineraryLoaded) {
      final currentState = state as ItineraryLoaded;
      emit(currentState.copyWith(searchQuery: query));
    }

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      if (query == _currentSearchQuery) return;
      _currentSearchQuery = query;
      loadData(keepCurrentList: true);
    });
  }

  void clearSearch() {
    _searchDebounce?.cancel();
    if (_currentSearchQuery.isEmpty &&
        (state is! ItineraryLoaded ||
            (state as ItineraryLoaded).searchQuery.isEmpty)) {
      return;
    }
    _currentSearchQuery = '';
    if (state is ItineraryLoaded) {
      emit(
        (state as ItineraryLoaded).copyWith(searchQuery: '', isSearching: true),
      );
    }
    loadData(keepCurrentList: true);
  }

  Future<void> deleteItem(String id) async {
    try {
      await _deleteItinerary(id);
      await loadData();
    } catch (e) {
      emit(ItineraryError('Không thể xóa lịch trình: ${e.toString()}'));
    }
  }

  Future<void> updateItineraryTitle(String id, String title) async {
    if (state is! ItineraryLoaded) return;
    final previousState = state as ItineraryLoaded;

    // Optimistic update: cập nhật UI ngay lập tức
    if (previousState.selectedItinerary?.id == id) {
      final updatedItineraries = previousState.itineraries
          .map((e) => e.id == id ? e.copyWith(title: title) : e)
          .toList();
      emit(
        ItineraryLoaded(
          itineraries: updatedItineraries,
          summary: previousState.summary,
          activeFilter: previousState.activeFilter,
          activeCompletedFilter: previousState.activeCompletedFilter,
          selectedItinerary: previousState.selectedItinerary!.copyWith(
            title: title,
          ),
          searchQuery: previousState.searchQuery,
          isSearching: previousState.isSearching,
        ),
      );
    }

    try {
      if (!kDemoMode) {
        await _updateTitle(id, title);
      }
    } catch (e) {
      // Rollback về state cũ nếu API lỗi
      emit(
        ItineraryError('Không thể cập nhật tên lịch trình: ${e.toString()}'),
      );
      emit(previousState);
    }
  }

  Future<void> selectItinerary(String id) async {
    final currentState = state;
    if (currentState is ItineraryLoaded) {
      emit(currentState.copyWithSelected(null));
      try {
        final detail = await _getItineraryDetail(id);
        final materializedDetail = _materializeMockDays(detail);
        emit((state as ItineraryLoaded).copyWithSelected(materializedDetail));
      } catch (e) {
        if (kDemoMode) {
          final ItineraryDetailEntity mockDetail;
          if (id == 'mock_saigon') {
            mockDetail = _buildSaigonDetail(id);
          } else {
            mockDetail = ItineraryDetailEntity(
              id: id,
              title: 'Đà Nẵng - Thành phố đáng sống',
              destination: 'Đà Nẵng',
              startDate: DateTime.now(),
              endDate: DateTime.now().add(const Duration(days: 3)),
              status: 'ONGOING',
              durationDays: 3,
              activitiesCount: 5,
              visitedLocations: 2,
              totalLocations: 5,
              hotelsCount: 1,
              transportTurns: 3,
              estimatedBudget: 4500000,
              spentBudget: 1200000,
              currency: 'VNĐ',
              days: [],
              notes: [],
              visitedRestaurants: [],
              centerCoordinate: [16.0611, 108.2274],
            );
          }
          emit(
            (state as ItineraryLoaded).copyWithSelected(
              _materializeMockDays(mockDetail),
            ),
          );
        } else {
          emit(
            currentState.copyWith(
              detailError: 'Không thể tải chi tiết: ${e.toString()}',
            ),
          );
        }
      }
    }
  }

  Future<void> ensureItinerarySelected(String id) async {
    if (state is! ItineraryLoaded) {
      await loadData();
    }

    final currentState = state;
    if (currentState is ItineraryLoaded &&
        currentState.selectedItinerary?.id != id) {
      await selectItinerary(id);
    }
  }

  /// Refresh chi tiết lịch trình mà không xóa dữ liệu hiện tại khỏi màn hình.
  /// Dùng cho pull-to-refresh: data cũ vẫn hiển thị, chỉ thay thế khi có data mới.
  Future<void> refreshDetail(String id) async {
    if (state is! ItineraryLoaded) return;
    try {
      final detail = await _getItineraryDetail(id);
      if (!isClosed && state is ItineraryLoaded) {
        emit(
          (state as ItineraryLoaded).copyWithSelected(
            _materializeMockDays(detail),
          ),
        );
      }
    } catch (_) {
      // Silent — không làm gián đoạn UI khi refresh lỗi
    }
  }

  ItineraryDetailEntity _materializeMockDays(ItineraryDetailEntity itin) {
    if (!kDemoMode) return itin;
    if (itin.days.isNotEmpty) return itin;

    final firstDayDate = itin.startDate;

    // ✅ DỮ LIỆU DEMO ĐÀ NẴNG - CÁC ĐIỂM CỰC GẦN NHAU
    final mockActivitiesDay1 = [
      ItineraryActivityEntity(
        id: 'dn_1',
        title: 'Bảo tàng Điêu khắc Chăm',
        locationName: 'Bảo tàng Chăm',
        address: 'Số 02 2 Tháng 9, Bình Hiên, Hải Châu',
        startTime: '08:30',
        endTime: '10:00',
        imageUrl:
            'https://images.unsplash.com/photo-1555412654-72a95a495858?w=600&q=80',
        transportInfo: 'Điểm xuất phát',
        rating: 4.5,
        reviewCount: 2500,
        price: 60000,
        status: ActivityStatus.daDi,
        latitude: 16.0614,
        longitude: 108.2248, // Tọa độ thật
      ),
      ItineraryActivityEntity(
        id: 'dn_2',
        title: 'Cầu Rồng Đà Nẵng',
        locationName: 'Cầu Rồng',
        address: 'An Hải Tây, Sơn Trà, Đà Nẵng',
        startTime: '10:15',
        endTime: '11:00',
        imageUrl:
            'https://images.unsplash.com/photo-1528127269322-539801943592?w=600&q=80',
        transportInfo: '5 phút di chuyển (300m)',
        rating: 4.8,
        reviewCount: 45000,
        isFree: true,
        status: ActivityStatus.daDi,
        latitude: 16.0611,
        longitude: 108.2274, // Tọa độ thật
      ),
      ItineraryActivityEntity(
        id: 'dn_3',
        title: 'Nhà thờ Chính tòa (Con Gà)',
        locationName: 'Nhà thờ Con Gà',
        address: '156 Trần Phú, Hải Châu 1',
        startTime: '11:15',
        endTime: '12:00',
        imageUrl:
            'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=600&q=80',
        transportInfo: '10 phút di chuyển (800m)',
        rating: 4.6,
        reviewCount: 8200,
        isFree: true,
        latitude: 16.0664,
        longitude: 108.2227, // Tọa độ thật
      ),
      ItineraryActivityEntity(
        id: 'dn_4',
        title: 'Chợ Hàn',
        locationName: 'Chợ Hàn',
        address: '119 Trần Phú, Hải Châu 1',
        startTime: '12:15',
        endTime: '13:30',
        imageUrl:
            'https://images.unsplash.com/photo-1579783902614-a3fb3927b6a5?w=600&q=80',
        transportInfo: '3 phút di chuyển (200m)',
        rating: 4.3,
        reviewCount: 15000,
        isFree: true,
        latitude: 16.0682,
        longitude: 108.2244, // Tọa độ thật
      ),
    ];

    final mockActivitiesDay2 = [
      ItineraryActivityEntity(
        id: 'dn_5',
        title: 'Bãi biển Mỹ Khê',
        locationName: 'Mỹ Khê Beach',
        address: 'Phước Mỹ, Sơn Trà, Đà Nẵng',
        startTime: '06:00',
        endTime: '08:00',
        imageUrl:
            'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600&q=80',
        transportInfo: 'Điểm xuất phát',
        rating: 4.7,
        reviewCount: 32000,
        isFree: true,
        status: ActivityStatus.chuaDi,
        latitude: 16.0544,
        longitude: 108.2450,
      ),
      ItineraryActivityEntity(
        id: 'dn_6',
        title: 'Cầu Tình Yêu',
        locationName: 'Love Lock Bridge',
        address: 'Trần Hưng Đạo, Sơn Trà, Đà Nẵng',
        startTime: '08:30',
        endTime: '09:30',
        imageUrl:
            'https://images.unsplash.com/photo-1506748686214-e9df14d4d9d0?w=600&q=80',
        transportInfo: '10 phút di chuyển (600m)',
        rating: 4.4,
        reviewCount: 12000,
        isFree: true,
        status: ActivityStatus.chuaDi,
        latitude: 16.0588,
        longitude: 108.2282,
      ),
      ItineraryActivityEntity(
        id: 'dn_7',
        title: 'Công viên APEC',
        locationName: 'APEC Park',
        address: '2 Tháng 9, Hải Châu, Đà Nẵng',
        startTime: '10:00',
        endTime: '11:30',
        imageUrl:
            'https://images.unsplash.com/photo-1519681393784-d120267933ba?w=600&q=80',
        transportInfo: '15 phút di chuyển (1.2km)',
        rating: 4.5,
        reviewCount: 8500,
        isFree: true,
        status: ActivityStatus.chuaDi,
        latitude: 16.0530,
        longitude: 108.2280,
      ),
    ];

    final mockActivitiesDay3 = [
      ItineraryActivityEntity(
        id: 'hcm_1',
        title: 'Dinh Độc Lập',
        locationName: 'Independence Palace',
        address: '135 Nam Kỳ Khởi Nghĩa, Quận 1, TP.HCM',
        startTime: '08:00',
        endTime: '10:00',
        imageUrl:
            'https://images.unsplash.com/photo-1583417319070-4a69db38a482?w=600&q=80',
        transportInfo: 'Điểm xuất phát',
        rating: 4.6,
        reviewCount: 25000,
        status: ActivityStatus.chuaDi,
        latitude: 10.7770,
        longitude: 106.6953,
      ),
      ItineraryActivityEntity(
        id: 'hcm_2',
        title: 'Nhà thờ Đức Bà',
        locationName: 'Notre-Dame Cathedral',
        address: '01 Công xã Paris, Bến Nghé, Quận 1',
        startTime: '10:30',
        endTime: '11:30',
        imageUrl:
            'https://images.unsplash.com/photo-1555913334-39941c16c6ba?w=600&q=80',
        transportInfo: '5 phút di chuyển (400m)',
        rating: 4.7,
        reviewCount: 18000,
        status: ActivityStatus.chuaDi,
        latitude: 10.7797,
        longitude: 106.6990,
      ),
    ];

    final mockActivitiesDay4 = [
      ItineraryActivityEntity(
        id: 'hs_1',
        title: 'Quần đảo Hoàng Sa',
        locationName: 'Paracel Islands',
        address: 'Huyện Hoàng Sa, TP. Đà Nẵng, Việt Nam',
        startTime: '08:00',
        endTime: '17:00',
        imageUrl:
            'https://images.unsplash.com/photo-1506461883276-594a12b11cf3?w=600&q=80',
        transportInfo: 'Di chuyển bằng tàu/máy bay',
        rating: 5.0,
        reviewCount: 1000,
        status: ActivityStatus.chuaDi,
        latitude: 16.5000,
        longitude: 112.0000,
      ),
      ItineraryActivityEntity(
        id: 'ts_1',
        title: 'Quần đảo Trường Sa',
        locationName: 'Spratly Islands',
        address: 'Huyện Trường Sa, Tỉnh Khánh Hòa, Việt Nam',
        startTime: '08:00',
        endTime: '17:00',
        imageUrl:
            'https://images.unsplash.com/photo-1559128010-7c1ad6e1b6a5?w=600&q=80',
        transportInfo: 'Di chuyển bằng tàu',
        rating: 5.0,
        reviewCount: 2000,
        status: ActivityStatus.chuaDi,
        latitude: 10.0000,
        longitude: 114.0000,
      ),
    ];

    final List<ItineraryDayEntity> displayDays = [
      ItineraryDayEntity(
        dayNumber: 1,
        date: firstDayDate,
        temperature: 31,
        totalDuration: '5 giờ tham quan',
        locationsCount: mockActivitiesDay1.length,
        dayBudget: 60000.0,
        activities: mockActivitiesDay1,
      ),
      ItineraryDayEntity(
        dayNumber: 2,
        date: firstDayDate.add(const Duration(days: 1)),
        temperature: 30,
        totalDuration: '6 giờ tham quan',
        locationsCount: mockActivitiesDay2.length,
        dayBudget: 0.0,
        activities: mockActivitiesDay2,
      ),
      ItineraryDayEntity(
        dayNumber: 3,
        date: firstDayDate.add(const Duration(days: 2)),
        temperature: 33,
        totalDuration: '4 giờ tham quan',
        locationsCount: mockActivitiesDay3.length,
        dayBudget: 0.0,
        activities: mockActivitiesDay3,
      ),
      ItineraryDayEntity(
        dayNumber: 4,
        date: firstDayDate.add(const Duration(days: 3)),
        temperature: 28,
        totalDuration: 'Toàn ngày',
        locationsCount: mockActivitiesDay4.length,
        dayBudget: 0.0,
        activities: mockActivitiesDay4,
      ),
    ];

    return itin.copyWith(days: displayDays);
  }

  ItineraryDetailEntity _buildSaigonDetail(String id) {
    ItineraryActivityEntity a(
      String aid,
      String title,
      String start,
      String end,
      String addr,
      String img,
      String transport, {
      double price = 0,
      bool isFree = false,
      double? lat,
      double? lng,
      double rating = 4.5,
      int reviewCount = 1000,
      ActivityStatus status = ActivityStatus.chuaDi,
    }) {
      return ItineraryActivityEntity(
        id: aid,
        title: title,
        locationName: title,
        address: addr,
        startTime: start,
        endTime: end,
        imageUrl: img,
        transportInfo: transport,
        price: price,
        isFree: isFree,
        rating: rating,
        reviewCount: reviewCount,
        latitude: lat,
        longitude: lng,
        status: status,
      );
    }

    final day1 = [
      a(
        'sg1_1',
        'Phở Hòa Pasteur',
        '08:00',
        '09:00',
        '260C Pasteur, Phường Xuân Hòa, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=600&q=80',
        'Điểm xuất phát',
        price: 95000,
        lat: 10.7790,
        lng: 106.6876,
        rating: 4.7,
        reviewCount: 12000,
      ),
      a(
        'sg1_2',
        'Dinh Độc Lập',
        '09:15',
        '11:15',
        '135 Nam Kỳ Khởi Nghĩa, Phường Sài Gòn, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1592114714621-ccc6cacad26b?w=600&q=80',
        '8 phút di chuyển (1km)',
        price: 40000,
        lat: 10.7770,
        lng: 106.6953,
        rating: 4.6,
        reviewCount: 25000,
      ),
      a(
        'sg1_3',
        'Nhà thờ Đức Bà',
        '11:30',
        '12:15',
        '01 Công xã Paris, Phường Sài Gòn, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1589601643522-dc444d89a2d0?w=600&q=80',
        '5 phút di chuyển (400m)',
        isFree: true,
        lat: 10.7797,
        lng: 106.6990,
        rating: 4.7,
        reviewCount: 18000,
      ),
      a(
        'sg1_4',
        'Cơm tấm Bụi Sài Gòn',
        '12:30',
        '13:30',
        '84 Đinh Tiên Hoàng, Phường Sài Gòn, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=600&q=80',
        '5 phút di chuyển (400m)',
        price: 85000,
        lat: 10.7756,
        lng: 106.6991,
        rating: 4.5,
        reviewCount: 8500,
      ),
      a(
        'sg1_5',
        'Liberty Central Saigon Citypoint',
        '14:00',
        '14:30',
        '59-61 Pasteur, Phường Sài Gòn, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=600&q=80',
        '5 phút di chuyển (400m)',
        price: 1200000,
        lat: 10.7757,
        lng: 106.7033,
        rating: 4.4,
        reviewCount: 3200,
      ),
      a(
        'sg1_6',
        'Chợ Bến Thành',
        '15:00',
        '17:00',
        'Lê Lợi, Phường Bến Thành, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1562147600-ee6e0707973b?w=600&q=80',
        '10 phút di chuyển (800m)',
        isFree: true,
        lat: 10.7722,
        lng: 106.6983,
        rating: 4.3,
        reviewCount: 32000,
      ),
      a(
        'sg1_7',
        'Phố đi bộ Nguyễn Huệ',
        '17:15',
        '18:45',
        'Nguyễn Huệ, Phường Sài Gòn, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1521019795854-14e15f600980?w=600&q=80',
        '5 phút di chuyển (400m)',
        isFree: true,
        lat: 10.7741,
        lng: 106.7029,
        rating: 4.6,
        reviewCount: 45000,
      ),
      a(
        'sg1_8',
        'Nhà hàng Cục Gạch Quán',
        '19:30',
        '21:00',
        '10 Đặng Tất, Phường Tân Định, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=600&q=80',
        '15 phút di chuyển (2.5km)',
        price: 280000,
        lat: 10.7912,
        lng: 106.6870,
        rating: 4.8,
        reviewCount: 6200,
      ),
      a(
        'sg1_9',
        'Chill Skybar',
        '21:30',
        '22:00',
        '76 Lê Lai, Phường Bến Thành, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1551024709-8f23befc6f87?w=600&q=80',
        '10 phút di chuyển (1.5km)',
        price: 200000,
        lat: 10.7709,
        lng: 106.6980,
        rating: 4.5,
        reviewCount: 4800,
      ),
    ];

    final day2 = [
      a(
        'sg2_1',
        'Bánh mì Huỳnh Hoa',
        '08:00',
        '09:00',
        '26 Lê Thị Riêng, Phường Bến Thành, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=600&q=80',
        'Điểm xuất phát',
        price: 55000,
        lat: 10.7773,
        lng: 106.6948,
        rating: 4.8,
        reviewCount: 22000,
      ),
      a(
        'sg2_2',
        'Bảo tàng Chứng tích Chiến tranh',
        '09:15',
        '11:30',
        '28 Võ Văn Tần, Phường Xuân Hòa, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1704635820420-02bc7364c3be?w=600&q=80',
        '8 phút di chuyển (1.2km)',
        price: 40000,
        lat: 10.7797,
        lng: 106.6930,
        rating: 4.7,
        reviewCount: 35000,
      ),
      a(
        'sg2_3',
        'Chùa Vĩnh Nghiêm',
        '11:45',
        '12:45',
        '339 Nam Kỳ Khởi Nghĩa, Phường Nhiêu Lộc, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1598791076033-5d11da0a734f?w=600&q=80',
        '12 phút di chuyển (2.5km)',
        isFree: true,
        lat: 10.7570,
        lng: 106.6879,
        rating: 4.5,
        reviewCount: 9800,
      ),
      a(
        'sg2_4',
        'Nhà hàng Ngon 160 Pasteur',
        '13:00',
        '14:00',
        '160 Pasteur, Phường Xuân Hòa, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1463424591693-a7c7ed4e3342?w=600&q=80',
        '10 phút di chuyển (1.5km)',
        price: 180000,
        lat: 10.7802,
        lng: 106.6887,
        rating: 4.6,
        reviewCount: 14000,
      ),
      a(
        'sg2_5',
        'Liberty Central Saigon Citypoint',
        '14:15',
        '15:00',
        '59-61 Pasteur, Phường Sài Gòn, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=600&q=80',
        '5 phút di chuyển (800m)',
        isFree: true,
        lat: 10.7757,
        lng: 106.7033,
        rating: 4.4,
        reviewCount: 3200,
      ),
      a(
        'sg2_6',
        'Chùa Bà Thiên Hậu',
        '15:30',
        '17:00',
        '710 Nguyễn Trãi, Phường Chợ Lớn, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1486056997767-09578eee7de1?w=600&q=80',
        '25 phút di chuyển (6km)',
        isFree: true,
        lat: 10.7547,
        lng: 106.6637,
        rating: 4.6,
        reviewCount: 11000,
      ),
      a(
        'sg2_7',
        'Khu phố người Hoa - Chợ Lớn',
        '17:15',
        '19:00',
        'Nguyễn Trãi, Phường An Đông, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1602917381237-e46b6c517705?w=600&q=80',
        '5 phút di chuyển (500m)',
        isFree: true,
        lat: 10.7540,
        lng: 106.6620,
        rating: 4.4,
        reviewCount: 18000,
      ),
      a(
        'sg2_8',
        'Lẩu riêu cua đồng Ngọc Xuân',
        '19:30',
        '21:00',
        '84 Đinh Tiên Hoàng, Phường Sài Gòn, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1562403492-454d4b075cac?w=600&q=80',
        '30 phút di chuyển (8km)',
        price: 250000,
        lat: 10.7740,
        lng: 106.7020,
        rating: 4.5,
        reviewCount: 7600,
      ),
      a(
        'sg2_9',
        'Phố Tây Bùi Viện',
        '21:30',
        '22:00',
        'Bùi Viện, Phường Bến Thành, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1541079033018-63489731598f?w=600&q=80',
        '10 phút di chuyển (1.5km)',
        isFree: true,
        lat: 10.7678,
        lng: 106.6949,
        rating: 4.2,
        reviewCount: 28000,
      ),
    ];

    final day3 = [
      a(
        'sg3_1',
        'Cháo lòng Kỳ Đồng',
        '08:00',
        '09:00',
        '47 Kỳ Đồng, Phường Bàn Cờ, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1533787761082-492a5b83e614?w=600&q=80',
        'Điểm xuất phát',
        price: 55000,
        lat: 10.7816,
        lng: 106.6888,
        rating: 4.4,
        reviewCount: 5200,
      ),
      a(
        'sg3_2',
        'Bến Nhà Rồng - Bảo tàng Hồ Chí Minh',
        '09:15',
        '11:15',
        '1 Nguyễn Tất Thành, Phường Khánh Hội, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1586004551686-d9c4fab26471?w=600&q=80',
        '15 phút di chuyển (2.5km)',
        price: 30000,
        lat: 10.7627,
        lng: 106.7028,
        rating: 4.5,
        reviewCount: 20000,
      ),
      a(
        'sg3_3',
        'Bạch Đằng Wharf - Bờ sông Sài Gòn',
        '11:30',
        '12:30',
        'Bến Bạch Đằng, Phường Sài Gòn, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1592982349625-b89ecccd6a12?w=600&q=80',
        '15 phút di chuyển (2km)',
        isFree: true,
        lat: 10.7738,
        lng: 106.7040,
        rating: 4.5,
        reviewCount: 16000,
      ),
      a(
        'sg3_4',
        'Cơm niêu Sài Gòn',
        '12:45',
        '13:45',
        '2C Đinh Tiên Hoàng, Phường Tân Định, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=600&q=80',
        '5 phút di chuyển (400m)',
        price: 130000,
        lat: 10.7756,
        lng: 106.6993,
        rating: 4.6,
        reviewCount: 9400,
      ),
      a(
        'sg3_5',
        'Liberty Central Saigon Citypoint',
        '14:00',
        '14:30',
        '59-61 Pasteur, Phường Sài Gòn, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=600&q=80',
        '5 phút di chuyển (400m)',
        isFree: true,
        lat: 10.7757,
        lng: 106.7033,
        rating: 4.4,
        reviewCount: 3200,
      ),
      a(
        'sg3_6',
        'Bitexco Financial Tower - Saigon Skydeck',
        '15:00',
        '17:00',
        '2 Hải Triều, Phường Sài Gòn, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1672910366209-698b5099546d?w=600&q=80',
        '10 phút di chuyển (1.5km)',
        price: 250000,
        lat: 10.7717,
        lng: 106.7020,
        rating: 4.5,
        reviewCount: 28000,
      ),
      a(
        'sg3_7',
        'Hoàng hôn bờ sông Sài Gòn',
        '17:15',
        '18:30',
        'Bến Bạch Đằng, Phường Sài Gòn, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1691048596859-457fbc612fe1?w=600&q=80',
        '5 phút di chuyển (400m)',
        isFree: true,
        lat: 10.7738,
        lng: 106.7040,
        rating: 4.8,
        reviewCount: 12000,
      ),
      a(
        'sg3_8',
        'Nhà hàng Cô Ba Vũng Tàu - Hải sản',
        '19:00',
        '21:00',
        '191 Lý Tự Trọng, Phường Sài Gòn, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=600&q=80',
        '15 phút di chuyển (2km)',
        price: 380000,
        lat: 10.7695,
        lng: 106.6950,
        rating: 4.6,
        reviewCount: 8900,
      ),
      a(
        'sg3_9',
        'Đường sách Nguyễn Văn Bình',
        '21:30',
        '22:00',
        'Nguyễn Văn Bình, Phường Sài Gòn, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1507842217343-583bb7270b66?w=600&q=80',
        '15 phút di chuyển (2km)',
        isFree: true,
        lat: 10.7786,
        lng: 106.6978,
        rating: 4.3,
        reviewCount: 6500,
      ),
    ];

    return ItineraryDetailEntity(
      id: id,
      title: 'Vi vu ở Sài Gòn',
      destination: 'TP. Hồ Chí Minh',
      startDate: DateTime(2026, 5, 8),
      endDate: DateTime(2026, 5, 10),
      status: 'UPCOMING',
      durationDays: 3,
      activitiesCount: 27,
      hotelsCount: 1,
      transportTurns: 8,
      visitedLocations: 0,
      totalLocations: 27,
      estimatedBudget: 6800000,
      spentBudget: 0,
      currency: 'VNĐ',
      centerCoordinate: [10.7769, 106.7009],
      notes: [
        'Mang theo áo mưa — tháng 5 là đầu mùa mưa ở Sài Gòn.',
        'Nên đặt Grab thay vì xe ôm truyền thống để tránh bị chặt chém.',
        'Chợ Bến Thành đông nhất buổi chiều, nên mặc cả khi mua hàng.',
        'Dinh Độc Lập đóng cửa thứ Hai, kiểm tra lại lịch mở cửa.',
      ],
      visitedRestaurants: const [],
      days: [
        ItineraryDayEntity(
          dayNumber: 1,
          date: DateTime(2026, 5, 8),
          temperature: 34,
          totalDuration: '9 giờ tham quan',
          locationsCount: 9,
          dayBudget: 1900000,
          activities: [],
        ),
        ItineraryDayEntity(
          dayNumber: 2,
          date: DateTime(2026, 5, 9),
          temperature: 33,
          totalDuration: '9 giờ tham quan',
          locationsCount: 9,
          dayBudget: 525000,
          activities: [],
        ),
        ItineraryDayEntity(
          dayNumber: 3,
          date: DateTime(2026, 5, 10),
          temperature: 35,
          totalDuration: '9 giờ tham quan',
          locationsCount: 9,
          dayBudget: 845000,
          activities: [],
        ),
      ],
    ).copyWith(
      days: [
        ItineraryDayEntity(
          dayNumber: 1,
          date: DateTime(2026, 5, 8),
          temperature: 34,
          totalDuration: '9 giờ tham quan',
          locationsCount: day1.length,
          dayBudget: 1900000,
          activities: day1,
        ),
        ItineraryDayEntity(
          dayNumber: 2,
          date: DateTime(2026, 5, 9),
          temperature: 33,
          totalDuration: '9 giờ tham quan',
          locationsCount: day2.length,
          dayBudget: 525000,
          activities: day2,
        ),
        ItineraryDayEntity(
          dayNumber: 3,
          date: DateTime(2026, 5, 10),
          temperature: 35,
          totalDuration: '9 giờ tham quan',
          locationsCount: day3.length,
          dayBudget: 845000,
          activities: day3,
        ),
      ],
    );
  }

  void toggleItineraryStatus(
    String id,
    bool isOngoing, {
    ItineraryStatus? stoppedStatus,
  }) {
    if (state is ItineraryLoaded) {
      final currentState = state as ItineraryLoaded;
      final targetStatus = isOngoing
          ? ItineraryStatus.ongoing
          : (stoppedStatus ?? ItineraryStatus.uncompleted);
      final updatedList = currentState.itineraries.map((itinerary) {
        if (itinerary.id == id) {
          return itinerary.copyWith(
            status: targetStatus,
            trackingActive: isOngoing,
          );
        }
        if (isOngoing && itinerary.status == ItineraryStatus.ongoing) {
          return itinerary.copyWith(
            status: ItineraryStatus.uncompleted,
            trackingActive: false,
          );
        }
        return itinerary;
      }).toList();

      final selected = currentState.selectedItinerary;
      final updatedSelected = selected?.id == id
          ? selected!.copyWith(
              status: isOngoing
                  ? 'ONGOING'
                  : (stoppedStatus == ItineraryStatus.completed
                        ? 'COMPLETED'
                        : 'UNCOMPLETED'),
              trackingActive: isOngoing,
            )
          : selected;

      emit(
        ItineraryLoaded(
          itineraries: updatedList,
          summary: currentState.summary,
          activeFilter: currentState.activeFilter,
          activeCompletedFilter: currentState.activeCompletedFilter,
          selectedItinerary: updatedSelected,
          searchQuery: currentState.searchQuery,
          isSearching: currentState.isSearching,
        ),
      );
    }
  }

  void setSelectedItineraryFavorite(bool isFavorite) {
    final currentState = state;
    if (currentState is! ItineraryLoaded ||
        currentState.selectedItinerary == null) {
      return;
    }

    emit(
      currentState.copyWith(
        selectedItinerary: currentState.selectedItinerary!.copyWith(
          isFavorite: isFavorite,
        ),
      ),
    );
  }

  void updateActivityTimeSingle(
    String activityId, {
    String? startTime,
    String? endTime,
  }) {
    if (state is ItineraryLoaded) {
      final currentState = state as ItineraryLoaded;
      final itin = currentState.selectedItinerary;
      if (itin == null) return;

      final updatedDays = itin.days.map((day) {
        final updatedActivities = day.activities.map((activity) {
          if (activity.id == activityId) {
            return activity.copyWith(
              startTime: startTime ?? activity.startTime,
              endTime: endTime ?? activity.endTime,
            );
          }
          return activity;
        }).toList();
        return day.copyWith(activities: updatedActivities);
      }).toList();

      emit(currentState.copyWithSelected(itin.copyWith(days: updatedDays)));
    }
  }

  // Nhận diện activity ăn trưa dựa theo category
  bool _isLunchActivity(ItineraryActivityEntity activity) {
    final cat = (activity.category ?? '').toLowerCase();
    return cat.contains('restaurant') ||
        cat.contains('nhà hàng') ||
        cat.contains('nha hang') ||
        cat.contains('quán ăn') ||
        cat.contains('quan an') ||
        cat.contains('buffet') ||
        cat.contains('ẩm thực') ||
        cat.contains('am thuc');
  }

  // Trả về (lunchWasPinned, lunchActivityTitle) để caller có thể thông báo cho user.
  // Khi protectLunchWindow=false (ví dụ lúc revert) không áp dụng ràng buộc ăn trưa.
  ({bool lunchWasPinned, String? lunchActivityTitle})
  updateActivityTimesWithShift({
    required String activityId,
    required int deltaMinutes,
    bool shiftStartTimeOnly =
        true, // true = đang chỉnh startTime, false = đang chỉnh endTime
    bool protectLunchWindow = true,
  }) {
    if (state is! ItineraryLoaded) {
      return (lunchWasPinned: false, lunchActivityTitle: null);
    }
    final currentState = state as ItineraryLoaded;
    final itin = currentState.selectedItinerary;
    if (itin == null) return (lunchWasPinned: false, lunchActivityTitle: null);

    int toMin(String t) {
      final p = t.split(':');
      return int.parse(p[0]) * 60 + int.parse(p[1]);
    }

    bool lunchWasPinned = false;
    String? lunchActivityTitle;

    final updatedDays = itin.days.map((day) {
      final hasActivity = day.activities.any((a) => a.id == activityId);
      if (!hasActivity) return day;

      bool foundActivity = false;
      final updatedActivities = day.activities.map((activity) {
        if (activity.id == activityId) {
          foundActivity = true;
          if (shiftStartTimeOnly) {
            // Đang chỉnh startTime → tịnh tiến cả activity hiện tại
            return activity.copyWith(
              startTime: _shiftTimeStr(activity.startTime, deltaMinutes),
              endTime: _shiftTimeStr(activity.endTime, deltaMinutes),
            );
          } else {
            // Đang chỉnh endTime → chỉ cập nhật endTime của activity hiện tại
            return activity.copyWith(
              endTime: _shiftTimeStr(activity.endTime, deltaMinutes),
            );
          }
        }
        // Các activity phía sau → kiểm tra ràng buộc ăn trưa trước khi tịnh tiến
        if (foundActivity) {
          // Nếu đã ghim ăn trưa → dừng propagation, giữ nguyên
          if (lunchWasPinned) return activity;

          if (protectLunchWindow && _isLunchActivity(activity)) {
            final newStartMin = toMin(activity.startTime) + deltaMinutes;
            final newEndMin = toMin(activity.endTime) + deltaMinutes;
            // Nếu tịnh tiến sẽ đẩy ăn trưa ra khỏi khung 11:30–13:30 → ghim lại
            if (newStartMin > _kLunchWindowEndMin ||
                newEndMin < _kLunchWindowStartMin) {
              lunchWasPinned = true;
              lunchActivityTitle = activity.title;
              return activity; // không dịch chuyển
            }
          }

          return activity.copyWith(
            startTime: _shiftTimeStr(activity.startTime, deltaMinutes),
            endTime: _shiftTimeStr(activity.endTime, deltaMinutes),
          );
        }
        return activity;
      }).toList();

      return day.copyWith(activities: updatedActivities);
    }).toList();

    emit(currentState.copyWithSelected(itin.copyWith(days: updatedDays)));
    return (
      lunchWasPinned: lunchWasPinned,
      lunchActivityTitle: lunchActivityTitle,
    );
  }

  String _shiftTimeStr(String timeStr, int deltaMinutes) {
    try {
      final parts = timeStr.split(':');
      final currentMin = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      var targetMin = currentMin + deltaMinutes;
      if (targetMin < 0) targetMin = 0;
      if (targetMin >= 24 * 60) targetMin = (24 * 60) - 1;

      final hour = targetMin ~/ 60;
      final minute = targetMin % 60;
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return timeStr;
    }
  }

  Future<List<String>> applyOptimizedDay(
    int dayNumber,
    bool allowReduceTime, {
    String? lockedActivityId,
  }) async {
    if (state is! ItineraryLoaded || optimizeDayUseCase == null) return [];
    final currentState = state as ItineraryLoaded;
    final itin = currentState.selectedItinerary;
    if (itin == null) return [];

    final dayData = itin.days.firstWhere(
      (d) => d.dayNumber == dayNumber,
      orElse: () => ItineraryDayEntity(
        dayNumber: dayNumber,
        date: DateTime.now(),
        activities: [],
        totalDuration: '0h',
        locationsCount: 0,
        dayBudget: 0.0,
      ),
    );

    if (dayData.activities.isEmpty) return [];

    try {
      final payload = {
        'activities': dayData.activities
            .map(
              (a) => {
                'id': a.id,
                'placeId': a.placeId,
                'title': a.title,
                'latitude': a.latitude,
                'longitude': a.longitude,
                'imageUrl': a.imageUrl,
                'rating': a.rating,
                'reviewCount': a.reviewCount,
                'address': a.address,
                'category': a.category,
                'startTime': a.startTime,
                'endTime': a.endTime,
                'isLocked': a.id == lockedActivityId,
                'lockedArriveTime': a.id == lockedActivityId
                    ? a.startTime
                    : null,
              },
            )
            .toList(),
        'dailyStartTime': itin.dailyStartTime,
        'dailyEndTime': itin.dailyEndTime,
        'allowReduceTime': allowReduceTime,
        'visitDate':
            '${dayData.date.year}-${dayData.date.month.toString().padLeft(2, '0')}-${dayData.date.day.toString().padLeft(2, '0')}',
      };

      final result = await optimizeDayUseCase!(itin.id, payload);

      final updatedDays = itin.days.map((day) {
        if (day.dayNumber == dayNumber) {
          return day.copyWith(activities: result.optimized);
        }
        return day;
      }).toList();

      emit(currentState.copyWithSelected(itin.copyWith(days: updatedDays)));

      return result.reorderNotes;
    } catch (e) {
      throw e;
    }
  }

  void discardChanges(ItineraryDetailEntity snapshot) {
    if (state is ItineraryLoaded) {
      emit((state as ItineraryLoaded).copyWithSelected(snapshot));
    }
  }

  Future<void> confirmUpdateItinerary(String id) async {
    if (state is! ItineraryLoaded) return;
    final currentState = state as ItineraryLoaded;
    final itin = currentState.selectedItinerary;
    if (itin == null) return;

    // Optimistic: cập nhật UI ngay bằng dữ liệu đã có trong memory,
    // không cần re-fetch vì server vừa nhận đúng data này.
    emit(currentState.copyWithSelected(itin));

    try {
      if (!kDemoMode) {
        await _updateActivities(id, itin.days);
        // Sau khi lưu xong, gọi selectItinerary để lấy data chuẩn xác từ DB (có thể AI vừa re-optimize)
        await selectItinerary(id);
      }
    } catch (e) {
      // Rollback về state cũ nếu API lỗi
      emit(ItineraryError('Không thể cập nhật lịch trình: ${e.toString()}'));
      emit(currentState);
    }
  }

  void rateActivity(String activityId, double rating) {
    if (state is ItineraryLoaded) {
      final currentState = state as ItineraryLoaded;
      final itin = currentState.selectedItinerary;
      if (itin == null) return;

      final updatedDays = itin.days.map((day) {
        final updatedActivities = day.activities.map((activity) {
          if (activity.id == activityId) {
            return activity.copyWith(rating: rating);
          }
          return activity;
        }).toList();
        return day.copyWith(activities: updatedActivities);
      }).toList();

      emit(currentState.copyWithSelected(itin.copyWith(days: updatedDays)));
    }
  }

  /// Trả về khung giờ hoạt động trong ngày theo thứ tự ưu tiên:
  /// 1. Giờ người dùng đặt lúc tạo lịch trình (dailyStartTime / dailyEndTime)
  /// 2. Derive từ các hoạt động thực tế của ngày đầu tiên có dữ liệu
  /// 3. Hardcode dự phòng cuối cùng khi không có bất kỳ dữ liệu nào
  ({String startTime, String endTime}) resolveTimeWindow(
    ItineraryDetailEntity itin,
  ) {
    final hasStart = itin.dailyStartTime?.isNotEmpty == true;
    final hasEnd = itin.dailyEndTime?.isNotEmpty == true;

    if (hasStart && hasEnd) {
      return (startTime: itin.dailyStartTime!, endTime: itin.dailyEndTime!);
    }

    // Derive từ ngày đầu tiên có hoạt động
    for (final day in itin.days) {
      if (day.activities.isEmpty) continue;
      final dayStart = hasStart
          ? itin.dailyStartTime!
          : day.activities.first.startTime;
      // Dùng fallback "22:00" thay vì last_activity.endTime + 90 phút.
      // Lý do: khi thêm địa điểm mới, lịch có thể kéo dài hơn giờ kết thúc hiện tại,
      // nên window cần đủ rộng để optimizer xếp được.
      final derivedEnd = hasEnd ? itin.dailyEndTime! : '22:00';
      return (startTime: dayStart, endTime: derivedEnd);
    }

    // Dự phòng cuối cùng — không có dữ liệu nào để dựa vào
    return (
      startTime: itin.dailyStartTime ?? '07:00',
      endTime: itin.dailyEndTime ?? '22:00',
    );
  }

  int _estimateTimeDiffMin(
    double? lat1,
    double? lng1,
    double? lat2,
    double? lng2,
  ) {
    if (lat1 == null || lng1 == null || lat2 == null || lng2 == null) return 5;
    final dist = _haversineKm(lat1, lng1, lat2, lng2);
    // Mô hình: đường thực tế ≈ Haversine × 1.3, tốc độ xe máy ~30 km/h
    // → phút = dist × 1.3 / 30 × 60 + 2 ≈ dist × 2.0 + 2
    // Ví dụ: 2km → 6 phút (khớp Google Maps), 5km → 12 phút
    return (dist * 2.0 + 2).ceil().clamp(3, 120);
  }

  ItineraryDayEntity _recalculateDayTimesSequential(
    ItineraryDayEntity day, {
    String? dailyStartTime,
  }) {
    if (day.activities.isEmpty) return day;

    int timeToMinutes(String timeStr) {
      final parts = timeStr.split(':');
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    }

    String minutesToTime(int min) {
      final h = (min ~/ 60) % 24;
      final m = min % 60;
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    }

    int currentMin = timeToMinutes(
      dailyStartTime ?? day.activities.first.startTime,
    );
    final List<ItineraryActivityEntity> newActs = [];

    for (int i = 0; i < day.activities.length; i++) {
      final act = day.activities[i];
      if (i > 0) {
        final prev = day.activities[i - 1];
        final travelMin = _estimateTimeDiffMin(
          prev.latitude,
          prev.longitude,
          act.latitude,
          act.longitude,
        );
        currentMin += travelMin;

        // Cập nhật transportInfo cho hoạt động trước đó
        newActs[i - 1] = newActs[i - 1].copyWith(
          transportInfo: '$travelMin phút di chuyển',
        );
      }

      final arrivalTime = minutesToTime(currentMin);
      final duration =
          timeToMinutes(act.endTime) - timeToMinutes(act.startTime);
      currentMin += (duration > 0 ? duration : 60); // default 60 min if invalid
      final departureTime = minutesToTime(currentMin);

      newActs.add(act.copyWith(startTime: arrivalTime, endTime: departureTime));
    }

    return day.copyWith(activities: newActs);
  }

  double haversineKm(double lat1, double lon1, double lat2, double lon2) {
    return _haversineKm(lat1, lon1, lat2, lon2);
  }

  Future<({bool success, bool isFull, bool canExtend, bool canReduceTime})>
  replaceActivity(
    String oldActivityId,
    String newPlaceId,
    String newPlaceName, {
    double? newLat,
    double? newLng,
    String? newImageUrl,
    double? newRating,
    int? newReviewCount,
    String? newAddress,
    String? newCategory,
    bool autoOptimize = true,
    bool allowReduceTime = false,
    bool extendTime = false,
  }) async {
    if (state is! ItineraryLoaded)
      return (
        success: false,
        isFull: false,
        canExtend: false,
        canReduceTime: false,
      );
    final currentState = state as ItineraryLoaded;
    final itin = currentState.selectedItinerary;
    if (itin == null)
      return (
        success: false,
        isFull: false,
        canExtend: false,
        canReduceTime: false,
      );

    emit(
      ItineraryLoading(
        message: autoOptimize
            ? 'Đang tìm vị trí phù hợp để thay thế...'
            : 'Đang thay thế địa điểm...',
      ),
    );

    // Thay thế địa điểm, giữ nguyên vị trí trong ngày
    var updatedDays = itin.days.map((day) {
      if (!day.activities.any((a) => a.id == oldActivityId)) return day;
      final updatedActivities = day.activities.map((a) {
        if (a.id != oldActivityId) return a;
        return a.copyWith(
          placeId: newPlaceId,
          title: newPlaceName,
          locationName: newPlaceName,
          latitude: newLat ?? a.latitude,
          longitude: newLng ?? a.longitude,
          imageUrl: newImageUrl ?? a.imageUrl,
          rating: newRating ?? a.rating,
          reviewCount: newReviewCount ?? a.reviewCount,
          address: newAddress ?? a.address,
          category: newCategory ?? a.category,
        );
      }).toList();
      return day.copyWith(activities: updatedActivities);
    }).toList();

    final dayNum =
        itin.days
            .cast<ItineraryDayEntity?>()
            .firstWhere(
              (d) => d!.activities.any((a) => a.id == oldActivityId),
              orElse: () => null,
            )
            ?.dayNumber ??
        updatedDays.first.dayNumber;

    if (autoOptimize) {
      final window = resolveTimeWindow(itin);
      final dayEntity = updatedDays.firstWhere(
        (d) => d.dayNumber == dayNum,
        orElse: () => updatedDays.first,
      );

      try {
        final finalDays = await _optimizeSpecificDay(
          updatedDays,
          dayNum,
          dailyStartTime: window.startTime,
          dailyEndTime: extendTime ? "23:59" : window.endTime,
          allowReduceTime: allowReduceTime,
          visitDate: dayEntity.date,
        );

        emit(currentState.copyWithSelected(itin.copyWith(days: finalDays)));
      } catch (e) {
        if (e.toString().contains('SCHEDULE_FULL')) {
          emit(currentState);

          int timeToMinutes(String timeStr) {
            final parts = timeStr.split(':');
            if (parts.length < 2) return 0;
            return int.parse(parts[0]) * 60 + int.parse(parts[1]);
          }

          bool possibleToReduce = false;
          int totalReducible = 0;
          for (final act in dayEntity.activities) {
            int actDuration =
                timeToMinutes(act.endTime) - timeToMinutes(act.startTime);
            if (actDuration <= 0) actDuration = 60;
            int minDur = (actDuration ~/ 2) < 15 ? 15 : (actDuration ~/ 2);
            totalReducible += (actDuration - minDur);
          }
          if (totalReducible >= 15) {
            possibleToReduce = true;
          }

          return (
            success: false,
            isFull: true,
            canExtend: true,
            canReduceTime: !allowReduceTime && possibleToReduce,
          );
        }
        rethrow;
      }
    } else {
      final testDayIndex = updatedDays.indexWhere((d) => d.dayNumber == dayNum);
      if (testDayIndex != -1) {
        updatedDays[testDayIndex] = _recalculateDayTimesSequential(
          updatedDays[testDayIndex],
        );
      }
      emit(currentState.copyWithSelected(itin.copyWith(days: updatedDays)));
    }

    return (success: true, isFull: false, canExtend: true, canReduceTime: true);
  }

  Future<
    ({
      String? activityId,
      int? dayNumber,
      bool isFull,
      bool canReduceTime,
      bool canExtend,
      bool canAddDay,
    })?
  >
  addActivityToDay(
    int dayNumber,
    String placeId,
    String placeName, {
    double? lat,
    double? lng,
    String? imageUrl,
    String? address,
    String? category,
    String? openHourCompressed,
    int durationMinutes = 60,
    bool allowReduceTime = false,
    bool extendTime = false,
    bool addExtraDay = false,
  }) async {
    if (state is! ItineraryLoaded) return null;
    final currentState = state as ItineraryLoaded;
    final itin = currentState.selectedItinerary;
    if (itin == null) return null;

    if (addExtraDay) {
      return await addDayAndActivity(
        placeId,
        placeName,
        lat: lat,
        lng: lng,
        imageUrl: imageUrl,
        address: address,
        category: category,
        openHourCompressed: openHourCompressed,
        durationMinutes: durationMinutes,
        allowReduceTime: allowReduceTime,
      );
    }

    emit(const ItineraryLoading(message: 'Đang tìm vị trí phù hợp để thêm...'));

    int targetDayNumber = -1;
    List<ItineraryDayEntity>? updatedDaysResult;
    String? newActivityId;

    final window = resolveTimeWindow(itin);
    final dailyStartTime = window.startTime;
    final dailyEndTime = window.endTime;

    int timeToMinutes(String timeStr) {
      final parts = timeStr.split(':');
      if (parts.length < 2) return 0;
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    }

    final dailyEndMin = timeToMinutes(dailyEndTime);

    // 5 phút buffer di chuyển tối thiểu trước khi hoạt động mới bắt đầu
    const kTravelBufferMin = 5;

    bool possibleToReduce = false;

    for (int i = 0; i < itin.days.length; i++) {
      int checkDayNum = ((dayNumber - 1 + i) % itin.days.length) + 1;
      final dayToTest = itin.days.firstWhere((d) => d.dayNumber == checkDayNum);

      String startTime = dailyStartTime;
      if (dayToTest.activities.isNotEmpty) {
        startTime = dayToTest.activities.last.endTime;
      }
      final endTime = _shiftTimeStr(startTime, durationMinutes);

      final estimatedEndMin =
          timeToMinutes(startTime) + kTravelBufferMin + durationMinutes;
      if (estimatedEndMin > dailyEndMin && !extendTime && !allowReduceTime) {
        int totalReducible = 0;
        for (final act in dayToTest.activities) {
          int actDuration =
              timeToMinutes(act.endTime) - timeToMinutes(act.startTime);
          if (actDuration <= 0) actDuration = 60;
          int minDur = (actDuration ~/ 2) < 15 ? 15 : (actDuration ~/ 2);
          totalReducible += (actDuration - minDur);
        }
        int newMinDur = (durationMinutes ~/ 2) < 15
            ? 15
            : (durationMinutes ~/ 2);
        totalReducible += (durationMinutes - newMinDur);

        if (estimatedEndMin - totalReducible <= dailyEndMin) {
          possibleToReduce = true;
        }
        continue; // Ngày này không đủ chỗ về thời gian, thử ngày tiếp theo
      }

      final newActivity = ItineraryActivityEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
        placeId: placeId,
        title: placeName,
        locationName: placeName,
        address: address ?? '',
        imageUrl: imageUrl ?? 'https://placehold.co/1080x720?text=New+Place',
        startTime: startTime,
        endTime: endTime,
        latitude: lat,
        longitude: lng,
        category: category,
        openHourCompressed: openHourCompressed,
      );

      newActivityId = newActivity.id;

      var candidateDays = itin.days.map((day) {
        if (day.dayNumber == checkDayNum) {
          return dayToTest.copyWith(
            activities: [...dayToTest.activities, newActivity],
          );
        }
        return day;
      }).toList();

      try {
        candidateDays = await _optimizeSpecificDay(
          candidateDays,
          checkDayNum,
          dailyStartTime: dailyStartTime,
          dailyEndTime: extendTime ? "23:59" : dailyEndTime,
          allowReduceTime: allowReduceTime,
          newActivityId: newActivity.id,
          visitDate: dayToTest.date,
        );
      } catch (e) {
        if (e.toString().contains('SCHEDULE_FULL')) {
          continue; // Try next day
        }
        rethrow;
      }

      final optimizedDay = candidateDays.firstWhere(
        (d) => d.dayNumber == checkDayNum,
      );
      final hasNewActivity = optimizedDay.activities.any(
        (a) => a.id == newActivity.id,
      );

      if (hasNewActivity) {
        targetDayNumber = checkDayNum;
        updatedDaysResult = candidateDays;
        break;
      }
    }

    if (targetDayNumber == -1 || updatedDaysResult == null) {
      // Khôi phục state cũ nhưng KHÔNG emit lỗi cứng ở đây, trả về để UI hỏi người dùng
      emit(currentState);
      return (
        activityId: null,
        dayNumber: null,
        isFull: true,
        canReduceTime: !allowReduceTime && possibleToReduce,
        canExtend: true,
        canAddDay: true,
      );
    }

    final newItin = itin.copyWith(days: updatedDaysResult);
    emit(currentState.copyWithSelected(newItin));

    return (
      activityId: newActivityId,
      dayNumber: targetDayNumber,
      isFull: false,
      canReduceTime: false,
      canExtend: true,
      canAddDay: true,
    );
  }

  Future<
    ({
      String? activityId,
      int? dayNumber,
      bool isFull,
      bool canReduceTime,
      bool canExtend,
      bool canAddDay,
    })?
  >
  addDayAndActivity(
    String placeId,
    String placeName, {
    double? lat,
    double? lng,
    String? imageUrl,
    String? address,
    String? category,
    String? openHourCompressed,
    int durationMinutes = 60,
    bool allowReduceTime = false,
  }) async {
    if (state is! ItineraryLoaded) return null;
    final currentState = state as ItineraryLoaded;
    final itin = currentState.selectedItinerary;
    if (itin == null) return null;

    final newDayNumber = itin.days.length + 1;
    final newDate = itin.days.last.date.add(const Duration(days: 1));

    final newDay = ItineraryDayEntity(
      dayNumber: newDayNumber,
      date: newDate,
      totalDuration: '0h',
      locationsCount: 0,
      dayBudget: 0.0,
      activities: [],
    );

    final newItin = itin.copyWith(
      days: [...itin.days, newDay],
      endDate: newDate,
    );

    emit(currentState.copyWithSelected(newItin));

    return await addActivityToDay(
      newDayNumber,
      placeId,
      placeName,
      lat: lat,
      lng: lng,
      imageUrl: imageUrl,
      address: address,
      category: category,
      openHourCompressed: openHourCompressed,
      durationMinutes: durationMinutes,
      allowReduceTime: false,
    );
  }

  /// Tổng khoảng cách Haversine của toàn bộ lộ trình (km).
  double _totalRouteDistanceKm(List<ItineraryActivityEntity> activities) {
    double total = 0;
    for (int i = 0; i < activities.length - 1; i++) {
      final a = activities[i];
      final b = activities[i + 1];
      if (a.latitude != null &&
          a.longitude != null &&
          b.latitude != null &&
          b.longitude != null) {
        total += _haversineKm(
          a.latitude!,
          a.longitude!,
          b.latitude!,
          b.longitude!,
        );
      }
    }
    return total;
  }

  double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLng = (lng2 - lng1) * math.pi / 180;
    final sinDLat = math.sin(dLat / 2);
    final sinDLng = math.sin(dLng / 2);
    final a =
        sinDLat * sinDLat +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            sinDLng *
            sinDLng;
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  /// Áp dụng lộ trình được đề xuất sau khi người dùng chấp nhận.
  void applySuggestedReorder() {
    if (state is! ItineraryLoaded) return;
    final s = state as ItineraryLoaded;
    if (s.suggestedDays == null || s.selectedItinerary == null) return;
    emit(
      ItineraryLoaded(
        itineraries: s.itineraries,
        summary: s.summary,
        activeFilter: s.activeFilter,
        activeCompletedFilter: s.activeCompletedFilter,
        selectedItinerary: s.selectedItinerary!.copyWith(
          days: s.suggestedDays!,
        ),
        searchQuery: s.searchQuery,
        isSearching: s.isSearching,
      ),
    );
  }

  /// Bỏ qua đề xuất sắp xếp lại.
  void dismissReorderSuggestion() {
    if (state is! ItineraryLoaded) return;
    final s = state as ItineraryLoaded;
    emit(s.copyWith(clearSuggestion: true));
  }

  Future<bool> deleteActivity(String activityId) async {
    if (state is ItineraryLoaded) {
      final currentState = state as ItineraryLoaded;
      final itin = currentState.selectedItinerary;
      if (itin == null) return false;

      int? updatedDayNum;
      var updatedDays = itin.days.map((day) {
        final hasActivity = day.activities.any((a) => a.id == activityId);
        if (!hasActivity) return day;

        updatedDayNum = day.dayNumber;
        final updatedActivities = day.activities
            .where((a) => a.id != activityId)
            .toList();
        return day.copyWith(activities: updatedActivities);
      }).toList();

      if (updatedDayNum != null) {
        // Optimistic UI update: xóa ngay lập tức khỏi màn hình
        emit(currentState.copyWithSelected(itin.copyWith(days: updatedDays)));

        final window = resolveTimeWindow(itin);
        final deletedDayEntity = itin.days.firstWhere(
          (d) => d.dayNumber == updatedDayNum,
          orElse: () => itin.days.first,
        );

        // Tính toán lại thời gian dồn lên cục bộ thay vì gọi API optimize để tránh làm xáo trộn và tốn thời gian
        final targetIdx = updatedDays.indexWhere(
          (d) => d.dayNumber == updatedDayNum,
        );
        if (targetIdx != -1) {
          updatedDays[targetIdx] = _recalculateDayTimesSequential(
            updatedDays[targetIdx],
            dailyStartTime: window.startTime,
          );
        }

        // Cập nhật UI ngay lập tức
        emit(currentState.copyWithSelected(itin.copyWith(days: updatedDays)));
      }

      return true;
    }
    return false;
  }

  Future<List<ItineraryDayEntity>> _optimizeSpecificDay(
    List<ItineraryDayEntity> days,
    int dayNumber, {
    String? dailyStartTime,
    String? dailyEndTime,
    bool allowReduceTime = false,
    String? newActivityId,
    DateTime? visitDate,
  }) async {
    String? visitDateStr;
    if (visitDate != null) {
      visitDateStr =
          '${visitDate.year}-${visitDate.month.toString().padLeft(2, '0')}-${visitDate.day.toString().padLeft(2, '0')}';
    }

    final List<ItineraryDayEntity> newDays = [];
    for (final d in days) {
      if (d.dayNumber == dayNumber) {
        final result = await OptimizeRouteApi.optimizeDay(
          d.activities,
          dailyStartTime: dailyStartTime,
          dailyEndTime: dailyEndTime,
          allowReduceTime: allowReduceTime,
          newActivityId: newActivityId,
          visitDate: visitDateStr,
        );
        final optimized = result.optimized;

        final List<ItineraryActivityEntity> actsWithTransport = List.from(
          optimized,
        );
        for (int i = 0; i < actsWithTransport.length - 1; i++) {
          final currentAct = actsWithTransport[i];
          final nextAct = actsWithTransport[i + 1];
          // Dùng Haversine để hiện thời gian di chuyển thực tế.
          // KHÔNG dùng gap thời gian (nextStart - currentEnd) vì gap đó bao gồm
          // cả thời gian rảnh trong lịch (VD: chợ đêm 19:00 sau activity kết thúc 09:00
          // sẽ cho gap = 10 tiếng, nhưng thực tế chỉ đi 6 phút).
          final transitMin = _estimateTimeDiffMin(
            currentAct.latitude,
            currentAct.longitude,
            nextAct.latitude,
            nextAct.longitude,
          );
          actsWithTransport[i] = currentAct.copyWith(
            transportInfo: '$transitMin phút di chuyển',
          );
        }

        if (actsWithTransport.isNotEmpty) {
          final lastIdx = actsWithTransport.length - 1;
          actsWithTransport[lastIdx] = actsWithTransport[lastIdx].copyWith(
            transportInfo: null,
          );
        }

        newDays.add(d.copyWith(activities: actsWithTransport));
      } else {
        newDays.add(d);
      }
    }
    return newDays;
  }
}

extension on ItineraryLoaded {
  ItineraryLoaded copyWithSelected(dynamic selected) {
    return ItineraryLoaded(
      itineraries: itineraries,
      summary: summary,
      activeFilter: activeFilter,
      activeCompletedFilter: activeCompletedFilter,
      selectedItinerary: selected,
      detailError: null,
      searchQuery: searchQuery,
      isSearching: isSearching,
      suggestedDays: null,
      suggestedDayNumber: null,
    );
  }

  ItineraryLoaded copyWith({
    List<ItineraryEntity>? itineraries,
    ItinerarySummary? summary,
    ItineraryStatus? activeFilter,
    CompletedFilter? activeCompletedFilter,
    ItineraryDetailEntity? selectedItinerary,
    String? detailError,
    String? searchQuery,
    bool? isSearching,
    List<ItineraryDayEntity>? suggestedDays,
    int? suggestedDayNumber,
    bool clearSuggestion = false,
  }) {
    return ItineraryLoaded(
      itineraries: itineraries ?? this.itineraries,
      summary: summary ?? this.summary,
      activeFilter: activeFilter ?? this.activeFilter,
      activeCompletedFilter:
          activeCompletedFilter ?? this.activeCompletedFilter,
      selectedItinerary: selectedItinerary ?? this.selectedItinerary,
      detailError: detailError,
      searchQuery: searchQuery ?? this.searchQuery,
      isSearching: isSearching ?? this.isSearching,
      suggestedDays: clearSuggestion
          ? null
          : (suggestedDays ?? this.suggestedDays),
      suggestedDayNumber: clearSuggestion
          ? null
          : (suggestedDayNumber ?? this.suggestedDayNumber),
    );
  }
}
