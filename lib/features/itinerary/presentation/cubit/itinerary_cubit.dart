import 'dart:math' as math;
import 'itinerary_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_activity_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_day_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_detail_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_summary.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/usecases/itinerary_usecases.dart';
import 'package:travel_advisor_mobile/core/config/app_config.dart';
import 'package:travel_advisor_mobile/core/utils/demo_review_store.dart';
import 'package:travel_advisor_mobile/features/itinerary/data/datasources/optimize_route_api.dart';

class ItineraryCubit extends Cubit<ItineraryState> {
  final GetItinerariesUseCase _getItineraries;
  final GetItinerarySummaryUseCase _getSummary;
  final DeleteItineraryUseCase _deleteItinerary;
  final GetItineraryDetailUseCase _getItineraryDetail;
  final UpdateItineraryActivitiesUseCase _updateActivities;

  ItineraryStatus? _currentFilter;
  CompletedFilter _currentCompletedFilter = CompletedFilter.all;

  ItineraryCubit({
    required GetItinerariesUseCase getItineraries,
    required GetItinerarySummaryUseCase getSummary,
    required DeleteItineraryUseCase deleteItinerary,
    required GetItineraryDetailUseCase getItineraryDetail,
    required UpdateItineraryActivitiesUseCase updateActivities,
  })  : _getItineraries = getItineraries,
        _getSummary = getSummary,
        _deleteItinerary = deleteItinerary,
        _getItineraryDetail = getItineraryDetail,
        _updateActivities = updateActivities,
        super(const ItineraryInitial());

  static const bool kDemoMode = AppConfig.kUseMockData;

  Future<void> loadData() async {
    emit(const ItineraryLoading());
    try {
      final results = await Future.wait([
        _getItineraries(status: _currentFilter),
        _getSummary(),
      ]);

      var itineraries = results[0] as List<ItineraryEntity>;
      
      if (_currentFilter == ItineraryStatus.completed) {
        if (_currentCompletedFilter == CompletedFilter.rated) {
          itineraries = itineraries.where((i) => i.rating != null).toList();
        } else if (_currentCompletedFilter == CompletedFilter.unrated) {
          itineraries = itineraries.where((i) => i.rating == null).toList();
        }
      }

      emit(ItineraryLoaded(
        itineraries: itineraries,
        summary: results[1] as dynamic,
        activeFilter: _currentFilter,
        activeCompletedFilter: _currentCompletedFilter,
        selectedItinerary: (state is ItineraryLoaded) ? (state as ItineraryLoaded).selectedItinerary : null,
      ));
    } catch (e) {
      if (kDemoMode) {
        final mockSummary = const ItinerarySummary(total: 5, draft: 2, upcoming: 1, completed: 1);
        final mockItineraries = [
          ItineraryEntity(
            id: 'mock_saigon', title: 'Vi vu ở Sài Gòn',
            startDate: DateTime(2026, 5, 8),
            endDate: DateTime(2026, 5, 10),
            status: ItineraryStatus.upcoming, progress: 0.0, estimatedCost: 6800000,
            visitedLocations: 0, totalLocations: 27,
          ),
          ItineraryEntity(
            id: 'mock_completed', title: 'Khám phá Đà Nẵng 3 ngày 2 đêm',
            startDate: DateTime.now().subtract(const Duration(days: 10)),
            endDate: DateTime.now().subtract(const Duration(days: 5)),
            status: ItineraryStatus.completed, progress: 1.0, estimatedCost: 4500000,
            rating: null, visitedLocations: 8, totalLocations: 8,
          ),
          ItineraryEntity(
            id: 'mock_ongoing', title: 'Hè rực rỡ tại Phú Quốc',
            startDate: DateTime.now().subtract(const Duration(days: 1)),
            endDate: DateTime.now().add(const Duration(days: 3)),
            status: ItineraryStatus.ongoing, progress: 0.8, estimatedCost: 8500000,
            visitedLocations: 10, totalLocations: 12,
          ),
        ];
        emit(ItineraryLoaded(
          itineraries: mockItineraries, summary: mockSummary,
          activeFilter: _currentFilter, activeCompletedFilter: _currentCompletedFilter,
          selectedItinerary: (state is ItineraryLoaded) ? (state as ItineraryLoaded).selectedItinerary : null,
        ));
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

  Future<void> deleteItem(String id) async {
    try {
      await _deleteItinerary(id);
      await loadData();
    } catch (e) {
      emit(ItineraryError('Không thể xóa lịch trình: ${e.toString()}'));
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
              id: id, title: 'Đà Nẵng - Thành phố đáng sống',
              destination: 'Đà Nẵng',
              startDate: DateTime.now(), endDate: DateTime.now().add(const Duration(days: 3)),
              status: 'ONGOING', durationDays: 3, activitiesCount: 5,
              visitedLocations: 2, totalLocations: 5,
              hotelsCount: 1, transportTurns: 3,
              estimatedBudget: 4500000, spentBudget: 1200000, currency: 'VNĐ', days: [], notes: [], visitedRestaurants: [],
              centerCoordinate: [16.0611, 108.2274],
            );
          }
          emit((state as ItineraryLoaded).copyWithSelected(_materializeMockDays(mockDetail)));
        } else {
          emit(currentState.copyWith(detailError: 'Không thể tải chi tiết: ${e.toString()}'));
        }
      }
    }
  }

  ItineraryDetailEntity _materializeMockDays(ItineraryDetailEntity itin) {
    if (itin.days.isNotEmpty) return itin;

    final firstDayDate = itin.startDate;

    // ✅ DỮ LIỆU DEMO ĐÀ NẴNG - CÁC ĐIỂM CỰC GẦN NHAU
    final mockActivitiesDay1 = [
      ItineraryActivityEntity(
        id: 'dn_1',
        title: 'Bảo tàng Điêu khắc Chăm',
        locationName: 'Bảo tàng Chăm',
        address: 'Số 02 2 Tháng 9, Bình Hiên, Hải Châu',
        startTime: '08:30', endTime: '10:00',
        imageUrl: 'https://images.unsplash.com/photo-1555412654-72a95a495858?w=600&q=80',
        transportInfo: 'Điểm xuất phát',
        rating: 4.5, reviewCount: 2500, price: 60000,
        status: ActivityStatus.daDi,
        latitude: 16.0614, longitude: 108.2248, // Tọa độ thật
      ),
      ItineraryActivityEntity(
        id: 'dn_2',
        title: 'Cầu Rồng Đà Nẵng',
        locationName: 'Cầu Rồng',
        address: 'An Hải Tây, Sơn Trà, Đà Nẵng',
        startTime: '10:15', endTime: '11:00',
        imageUrl: 'https://images.unsplash.com/photo-1528127269322-539801943592?w=600&q=80',
        transportInfo: '5 phút di chuyển (300m)',
        rating: 4.8, reviewCount: 45000, isFree: true,
        status: ActivityStatus.daDi,
        latitude: 16.0611, longitude: 108.2274, // Tọa độ thật
      ),
      ItineraryActivityEntity(
        id: 'dn_3',
        title: 'Nhà thờ Chính tòa (Con Gà)',
        locationName: 'Nhà thờ Con Gà',
        address: '156 Trần Phú, Hải Châu 1',
        startTime: '11:15', endTime: '12:00',
        imageUrl: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=600&q=80',
        transportInfo: '10 phút di chuyển (800m)',
        rating: 4.6, reviewCount: 8200, isFree: true,
        latitude: 16.0664, longitude: 108.2227, // Tọa độ thật
      ),
      ItineraryActivityEntity(
        id: 'dn_4',
        title: 'Chợ Hàn',
        locationName: 'Chợ Hàn',
        address: '119 Trần Phú, Hải Châu 1',
        startTime: '12:15', endTime: '13:30',
        imageUrl: 'https://images.unsplash.com/photo-1579783902614-a3fb3927b6a5?w=600&q=80',
        transportInfo: '3 phút di chuyển (200m)',
        rating: 4.3, reviewCount: 15000, isFree: true,
        latitude: 16.0682, longitude: 108.2244, // Tọa độ thật
      ),
    ];

    final mockActivitiesDay2 = [
      ItineraryActivityEntity(
        id: 'dn_5',
        title: 'Bãi biển Mỹ Khê',
        locationName: 'Mỹ Khê Beach',
        address: 'Phước Mỹ, Sơn Trà, Đà Nẵng',
        startTime: '06:00', endTime: '08:00',
        imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600&q=80',
        transportInfo: 'Điểm xuất phát',
        rating: 4.7, reviewCount: 32000, isFree: true,
        status: ActivityStatus.chuaDi,
        latitude: 16.0544, longitude: 108.2450,
      ),
      ItineraryActivityEntity(
        id: 'dn_6',
        title: 'Cầu Tình Yêu',
        locationName: 'Love Lock Bridge',
        address: 'Trần Hưng Đạo, Sơn Trà, Đà Nẵng',
        startTime: '08:30', endTime: '09:30',
        imageUrl: 'https://images.unsplash.com/photo-1506748686214-e9df14d4d9d0?w=600&q=80',
        transportInfo: '10 phút di chuyển (600m)',
        rating: 4.4, reviewCount: 12000, isFree: true,
        status: ActivityStatus.chuaDi,
        latitude: 16.0588, longitude: 108.2282,
      ),
      ItineraryActivityEntity(
        id: 'dn_7',
        title: 'Công viên APEC',
        locationName: 'APEC Park',
        address: '2 Tháng 9, Hải Châu, Đà Nẵng',
        startTime: '10:00', endTime: '11:30',
        imageUrl: 'https://images.unsplash.com/photo-1519681393784-d120267933ba?w=600&q=80',
        transportInfo: '15 phút di chuyển (1.2km)',
        rating: 4.5, reviewCount: 8500, isFree: true,
        status: ActivityStatus.chuaDi,
        latitude: 16.0530, longitude: 108.2280,
      ),
    ];

    final mockActivitiesDay3 = [
      ItineraryActivityEntity(
        id: 'hcm_1',
        title: 'Dinh Độc Lập',
        locationName: 'Independence Palace',
        address: '135 Nam Kỳ Khởi Nghĩa, Quận 1, TP.HCM',
        startTime: '08:00', endTime: '10:00',
        imageUrl: 'https://images.unsplash.com/photo-1583417319070-4a69db38a482?w=600&q=80',
        transportInfo: 'Điểm xuất phát',
        rating: 4.6, reviewCount: 25000,
        status: ActivityStatus.chuaDi,
        latitude: 10.7770, longitude: 106.6953,
      ),
      ItineraryActivityEntity(
        id: 'hcm_2',
        title: 'Nhà thờ Đức Bà',
        locationName: 'Notre-Dame Cathedral',
        address: '01 Công xã Paris, Bến Nghé, Quận 1',
        startTime: '10:30', endTime: '11:30',
        imageUrl: 'https://images.unsplash.com/photo-1555913334-39941c16c6ba?w=600&q=80',
        transportInfo: '5 phút di chuyển (400m)',
        rating: 4.7, reviewCount: 18000,
        status: ActivityStatus.chuaDi,
        latitude: 10.7797, longitude: 106.6990,
      ),
    ];

    final mockActivitiesDay4 = [
      ItineraryActivityEntity(
        id: 'hs_1',
        title: 'Quần đảo Hoàng Sa',
        locationName: 'Paracel Islands',
        address: 'Huyện Hoàng Sa, TP. Đà Nẵng, Việt Nam',
        startTime: '08:00', endTime: '17:00',
        imageUrl: 'https://images.unsplash.com/photo-1506461883276-594a12b11cf3?w=600&q=80',
        transportInfo: 'Di chuyển bằng tàu/máy bay',
        rating: 5.0, reviewCount: 1000,
        status: ActivityStatus.chuaDi,
        latitude: 16.5000, longitude: 112.0000,
      ),
      ItineraryActivityEntity(
        id: 'ts_1',
        title: 'Quần đảo Trường Sa',
        locationName: 'Spratly Islands',
        address: 'Huyện Trường Sa, Tỉnh Khánh Hòa, Việt Nam',
        startTime: '08:00', endTime: '17:00',
        imageUrl: 'https://images.unsplash.com/photo-1559128010-7c1ad6e1b6a5?w=600&q=80',
        transportInfo: 'Di chuyển bằng tàu',
        rating: 5.0, reviewCount: 2000,
        status: ActivityStatus.chuaDi,
        latitude: 10.0000, longitude: 114.0000,
      ),
    ];

    final List<ItineraryDayEntity> displayDays = [
      ItineraryDayEntity(
        dayNumber: 1, date: firstDayDate, temperature: 31,
        totalDuration: '5 giờ tham quan', locationsCount: mockActivitiesDay1.length,
        dayBudget: 60000.0, activities: mockActivitiesDay1,
      ),
      ItineraryDayEntity(
        dayNumber: 2, date: firstDayDate.add(const Duration(days: 1)), temperature: 30,
        totalDuration: '6 giờ tham quan', locationsCount: mockActivitiesDay2.length,
        dayBudget: 0.0, activities: mockActivitiesDay2,
      ),
      ItineraryDayEntity(
        dayNumber: 3, date: firstDayDate.add(const Duration(days: 2)), temperature: 33,
        totalDuration: '4 giờ tham quan', locationsCount: mockActivitiesDay3.length,
        dayBudget: 0.0, activities: mockActivitiesDay3,
      ),
      ItineraryDayEntity(
        dayNumber: 4, date: firstDayDate.add(const Duration(days: 3)), temperature: 28,
        totalDuration: 'Toàn ngày', locationsCount: mockActivitiesDay4.length,
        dayBudget: 0.0, activities: mockActivitiesDay4,
      ),
    ];

    return itin.copyWith(days: displayDays);
  }

  ItineraryDetailEntity _buildSaigonDetail(String id) {
    ItineraryActivityEntity a(
      String aid, String title, String start, String end, String addr,
      String img, String transport, {
      double price = 0, bool isFree = false,
      double? lat, double? lng,
      double rating = 4.5, int reviewCount = 1000,
      ActivityStatus status = ActivityStatus.chuaDi,
    }) {
      return ItineraryActivityEntity(
        id: aid, title: title, locationName: title,
        address: addr, startTime: start, endTime: end,
        imageUrl: img, transportInfo: transport,
        price: price, isFree: isFree,
        rating: rating, reviewCount: reviewCount,
        latitude: lat, longitude: lng, status: status,
      );
    }

    final day1 = [
      a('sg1_1', 'Phở Hòa Pasteur', '08:00', '09:00',
        '260C Pasteur, Phường Xuân Hòa, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=600&q=80',
        'Điểm xuất phát',
        price: 95000, lat: 10.7790, lng: 106.6876, rating: 4.7, reviewCount: 12000),
      a('sg1_2', 'Dinh Độc Lập', '09:15', '11:15',
        '135 Nam Kỳ Khởi Nghĩa, Phường Sài Gòn, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1592114714621-ccc6cacad26b?w=600&q=80',
        '8 phút di chuyển (1km)',
        price: 40000, lat: 10.7770, lng: 106.6953, rating: 4.6, reviewCount: 25000),
      a('sg1_3', 'Nhà thờ Đức Bà', '11:30', '12:15',
        '01 Công xã Paris, Phường Sài Gòn, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1589601643522-dc444d89a2d0?w=600&q=80',
        '5 phút di chuyển (400m)',
        isFree: true, lat: 10.7797, lng: 106.6990, rating: 4.7, reviewCount: 18000),
      a('sg1_4', 'Cơm tấm Bụi Sài Gòn', '12:30', '13:30',
        '84 Đinh Tiên Hoàng, Phường Sài Gòn, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=600&q=80',
        '5 phút di chuyển (400m)',
        price: 85000, lat: 10.7756, lng: 106.6991, rating: 4.5, reviewCount: 8500),
      a('sg1_5', 'Liberty Central Saigon Citypoint', '14:00', '14:30',
        '59-61 Pasteur, Phường Sài Gòn, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=600&q=80',
        '5 phút di chuyển (400m)',
        price: 1200000, lat: 10.7757, lng: 106.7033, rating: 4.4, reviewCount: 3200),
      a('sg1_6', 'Chợ Bến Thành', '15:00', '17:00',
        'Lê Lợi, Phường Bến Thành, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1562147600-ee6e0707973b?w=600&q=80',
        '10 phút di chuyển (800m)',
        isFree: true, lat: 10.7722, lng: 106.6983, rating: 4.3, reviewCount: 32000),
      a('sg1_7', 'Phố đi bộ Nguyễn Huệ', '17:15', '18:45',
        'Nguyễn Huệ, Phường Sài Gòn, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1521019795854-14e15f600980?w=600&q=80',
        '5 phút di chuyển (400m)',
        isFree: true, lat: 10.7741, lng: 106.7029, rating: 4.6, reviewCount: 45000),
      a('sg1_8', 'Nhà hàng Cục Gạch Quán', '19:30', '21:00',
        '10 Đặng Tất, Phường Tân Định, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=600&q=80',
        '15 phút di chuyển (2.5km)',
        price: 280000, lat: 10.7912, lng: 106.6870, rating: 4.8, reviewCount: 6200),
      a('sg1_9', 'Chill Skybar', '21:30', '22:00',
        '76 Lê Lai, Phường Bến Thành, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1551024709-8f23befc6f87?w=600&q=80',
        '10 phút di chuyển (1.5km)',
        price: 200000, lat: 10.7709, lng: 106.6980, rating: 4.5, reviewCount: 4800),
    ];

    final day2 = [
      a('sg2_1', 'Bánh mì Huỳnh Hoa', '08:00', '09:00',
        '26 Lê Thị Riêng, Phường Bến Thành, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=600&q=80',
        'Điểm xuất phát',
        price: 55000, lat: 10.7773, lng: 106.6948, rating: 4.8, reviewCount: 22000),
      a('sg2_2', 'Bảo tàng Chứng tích Chiến tranh', '09:15', '11:30',
        '28 Võ Văn Tần, Phường Xuân Hòa, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1704635820420-02bc7364c3be?w=600&q=80',
        '8 phút di chuyển (1.2km)',
        price: 40000, lat: 10.7797, lng: 106.6930, rating: 4.7, reviewCount: 35000),
      a('sg2_3', 'Chùa Vĩnh Nghiêm', '11:45', '12:45',
        '339 Nam Kỳ Khởi Nghĩa, Phường Nhiêu Lộc, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1598791076033-5d11da0a734f?w=600&q=80',
        '12 phút di chuyển (2.5km)',
        isFree: true, lat: 10.7570, lng: 106.6879, rating: 4.5, reviewCount: 9800),
      a('sg2_4', 'Nhà hàng Ngon 160 Pasteur', '13:00', '14:00',
        '160 Pasteur, Phường Xuân Hòa, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1463424591693-a7c7ed4e3342?w=600&q=80',
        '10 phút di chuyển (1.5km)',
        price: 180000, lat: 10.7802, lng: 106.6887, rating: 4.6, reviewCount: 14000),
      a('sg2_5', 'Liberty Central Saigon Citypoint', '14:15', '15:00',
        '59-61 Pasteur, Phường Sài Gòn, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=600&q=80',
        '5 phút di chuyển (800m)',
        isFree: true, lat: 10.7757, lng: 106.7033, rating: 4.4, reviewCount: 3200),
      a('sg2_6', 'Chùa Bà Thiên Hậu', '15:30', '17:00',
        '710 Nguyễn Trãi, Phường Chợ Lớn, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1486056997767-09578eee7de1?w=600&q=80',
        '25 phút di chuyển (6km)',
        isFree: true, lat: 10.7547, lng: 106.6637, rating: 4.6, reviewCount: 11000),
      a('sg2_7', 'Khu phố người Hoa - Chợ Lớn', '17:15', '19:00',
        'Nguyễn Trãi, Phường An Đông, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1602917381237-e46b6c517705?w=600&q=80',
        '5 phút di chuyển (500m)',
        isFree: true, lat: 10.7540, lng: 106.6620, rating: 4.4, reviewCount: 18000),
      a('sg2_8', 'Lẩu riêu cua đồng Ngọc Xuân', '19:30', '21:00',
        '84 Đinh Tiên Hoàng, Phường Sài Gòn, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1562403492-454d4b075cac?w=600&q=80',
        '30 phút di chuyển (8km)',
        price: 250000, lat: 10.7740, lng: 106.7020, rating: 4.5, reviewCount: 7600),
      a('sg2_9', 'Phố Tây Bùi Viện', '21:30', '22:00',
        'Bùi Viện, Phường Bến Thành, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1541079033018-63489731598f?w=600&q=80',
        '10 phút di chuyển (1.5km)',
        isFree: true, lat: 10.7678, lng: 106.6949, rating: 4.2, reviewCount: 28000),
    ];

    final day3 = [
      a('sg3_1', 'Cháo lòng Kỳ Đồng', '08:00', '09:00',
        '47 Kỳ Đồng, Phường Bàn Cờ, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1533787761082-492a5b83e614?w=600&q=80',
        'Điểm xuất phát',
        price: 55000, lat: 10.7816, lng: 106.6888, rating: 4.4, reviewCount: 5200),
      a('sg3_2', 'Bến Nhà Rồng - Bảo tàng Hồ Chí Minh', '09:15', '11:15',
        '1 Nguyễn Tất Thành, Phường Khánh Hội, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1586004551686-d9c4fab26471?w=600&q=80',
        '15 phút di chuyển (2.5km)',
        price: 30000, lat: 10.7627, lng: 106.7028, rating: 4.5, reviewCount: 20000),
      a('sg3_3', 'Bạch Đằng Wharf - Bờ sông Sài Gòn', '11:30', '12:30',
        'Bến Bạch Đằng, Phường Sài Gòn, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1592982349625-b89ecccd6a12?w=600&q=80',
        '15 phút di chuyển (2km)',
        isFree: true, lat: 10.7738, lng: 106.7040, rating: 4.5, reviewCount: 16000),
      a('sg3_4', 'Cơm niêu Sài Gòn', '12:45', '13:45',
        '2C Đinh Tiên Hoàng, Phường Tân Định, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=600&q=80',
        '5 phút di chuyển (400m)',
        price: 130000, lat: 10.7756, lng: 106.6993, rating: 4.6, reviewCount: 9400),
      a('sg3_5', 'Liberty Central Saigon Citypoint', '14:00', '14:30',
        '59-61 Pasteur, Phường Sài Gòn, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=600&q=80',
        '5 phút di chuyển (400m)',
        isFree: true, lat: 10.7757, lng: 106.7033, rating: 4.4, reviewCount: 3200),
      a('sg3_6', 'Bitexco Financial Tower - Saigon Skydeck', '15:00', '17:00',
        '2 Hải Triều, Phường Sài Gòn, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1672910366209-698b5099546d?w=600&q=80',
        '10 phút di chuyển (1.5km)',
        price: 250000, lat: 10.7717, lng: 106.7020, rating: 4.5, reviewCount: 28000),
      a('sg3_7', 'Hoàng hôn bờ sông Sài Gòn', '17:15', '18:30',
        'Bến Bạch Đằng, Phường Sài Gòn, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1691048596859-457fbc612fe1?w=600&q=80',
        '5 phút di chuyển (400m)',
        isFree: true, lat: 10.7738, lng: 106.7040, rating: 4.8, reviewCount: 12000),
      a('sg3_8', 'Nhà hàng Cô Ba Vũng Tàu - Hải sản', '19:00', '21:00',
        '191 Lý Tự Trọng, Phường Sài Gòn, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=600&q=80',
        '15 phút di chuyển (2km)',
        price: 380000, lat: 10.7695, lng: 106.6950, rating: 4.6, reviewCount: 8900),
      a('sg3_9', 'Đường sách Nguyễn Văn Bình', '21:30', '22:00',
        'Nguyễn Văn Bình, Phường Sài Gòn, TP. Hồ Chí Minh',
        'https://images.unsplash.com/photo-1507842217343-583bb7270b66?w=600&q=80',
        '15 phút di chuyển (2km)',
        isFree: true, lat: 10.7786, lng: 106.6978, rating: 4.3, reviewCount: 6500),
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
          dayNumber: 1, date: DateTime(2026, 5, 8), temperature: 34,
          totalDuration: '9 giờ tham quan', locationsCount: 9,
          dayBudget: 1900000, activities: [],
        ),
        ItineraryDayEntity(
          dayNumber: 2, date: DateTime(2026, 5, 9), temperature: 33,
          totalDuration: '9 giờ tham quan', locationsCount: 9,
          dayBudget: 525000, activities: [],
        ),
        ItineraryDayEntity(
          dayNumber: 3, date: DateTime(2026, 5, 10), temperature: 35,
          totalDuration: '9 giờ tham quan', locationsCount: 9,
          dayBudget: 845000, activities: [],
        ),
      ],
    ).copyWith(days: [
      ItineraryDayEntity(
        dayNumber: 1, date: DateTime(2026, 5, 8), temperature: 34,
        totalDuration: '9 giờ tham quan', locationsCount: day1.length,
        dayBudget: 1900000, activities: day1,
      ),
      ItineraryDayEntity(
        dayNumber: 2, date: DateTime(2026, 5, 9), temperature: 33,
        totalDuration: '9 giờ tham quan', locationsCount: day2.length,
        dayBudget: 525000, activities: day2,
      ),
      ItineraryDayEntity(
        dayNumber: 3, date: DateTime(2026, 5, 10), temperature: 35,
        totalDuration: '9 giờ tham quan', locationsCount: day3.length,
        dayBudget: 845000, activities: day3,
      ),
    ]);
  }

  void toggleItineraryStatus(String id, bool isOngoing) {
    if (state is ItineraryLoaded) {
      final currentState = state as ItineraryLoaded;
      final updatedList = currentState.itineraries.map((itinerary) {
        if (itinerary.id == id) {
          return itinerary.copyWith(
            status: isOngoing ? ItineraryStatus.ongoing : ItineraryStatus.upcoming,
            trackingActive: isOngoing,
          );
        }
        return itinerary;
      }).toList();

      emit(ItineraryLoaded(
        itineraries: updatedList,
        summary: currentState.summary,
        activeFilter: currentState.activeFilter,
        activeCompletedFilter: currentState.activeCompletedFilter,
        selectedItinerary: currentState.selectedItinerary,
      ));
    }
  }

  void updateActivityTimeSingle(String activityId, {String? startTime, String? endTime}) {
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

  void updateActivityTimesWithShift({
    required String activityId,
    required int deltaMinutes,
    bool shiftStartTimeOnly = true, // true = đang chỉnh startTime, false = đang chỉnh endTime
  }) {
    if (state is ItineraryLoaded) {
      final currentState = state as ItineraryLoaded;
      final itin = currentState.selectedItinerary;
      if (itin == null) return;

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
          // Các activity phía sau → tịnh tiến toàn bộ
          if (foundActivity) {
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
    }
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

  Future<void> replaceActivity(
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
  }) async {
    if (state is! ItineraryLoaded) return;
    final currentState = state as ItineraryLoaded;
    final itin = currentState.selectedItinerary;
    if (itin == null) return;

    emit(const ItineraryLoading());

    // Thay thế địa điểm, giữ nguyên vị trí trong ngày
    var updatedDays = itin.days.map((day) {
      if (!day.activities.any((a) => a.id == oldActivityId)) return day;
      final updatedActivities = day.activities.map((a) {
        if (a.id != oldActivityId) return a;
        return a.copyWith(
          id: newPlaceId,
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

    // Tìm ngày chứa địa điểm vừa thay thế
    int? dayNum;
    ItineraryDayEntity? originalDay;
    for (final d in itin.days) {
      if (d.activities.any((a) => a.id == oldActivityId)) {
        dayNum = d.dayNumber;
        originalDay = d;
        break;
      }
    }

    // Chạy OR-Tools để tìm lộ trình tối ưu sau khi thay thế
    List<ItineraryDayEntity>? optimizedDays;
    if (dayNum != null) {
      optimizedDays = await _optimizeSpecificDay(updatedDays, dayNum);
    }

    // So sánh tổng khoảng cách trước/sau để quyết định đề xuất sắp xếp lại
    List<ItineraryDayEntity>? suggestion;
    int? suggestionDayNum;
    if (originalDay != null && optimizedDays != null && dayNum != null) {
      final currentDay = updatedDays.firstWhere((d) => d.dayNumber == dayNum);
      final optimizedDay = optimizedDays.firstWhere((d) => d.dayNumber == dayNum);
      final distBefore = _totalRouteDistanceKm(currentDay.activities);
      final distAfter = _totalRouteDistanceKm(optimizedDay.activities);

      // Đề xuất nếu lộ trình tối ưu cải thiện > 15% khoảng cách
      if (distBefore > 0.5 && distAfter < distBefore * 0.85) {
        suggestion = optimizedDays;
        suggestionDayNum = dayNum;
      }
    }

    final finalDays = suggestion == null ? (optimizedDays ?? updatedDays) : updatedDays;
    final newState = ItineraryLoaded(
      itineraries: currentState.itineraries,
      summary: currentState.summary,
      activeFilter: currentState.activeFilter,
      activeCompletedFilter: currentState.activeCompletedFilter,
      selectedItinerary: itin.copyWith(days: finalDays),
      suggestedDays: suggestion,
      suggestedDayNumber: suggestionDayNum,
    );
    emit(newState);
  }

  Future<void> addActivityToDay(
    int dayNumber,
    String placeId,
    String placeName, {
    double? lat,
    double? lng,
    String? imageUrl,
    String? address,
    String? category,
  }) async {
    if (state is! ItineraryLoaded) return;
    final currentState = state as ItineraryLoaded;
    final itin = currentState.selectedItinerary;
    if (itin == null) return;

    emit(const ItineraryLoading());

    var updatedDays = itin.days.map((day) {
      if (day.dayNumber != dayNumber) return day;

      String startTime = '08:00';
      if (day.activities.isNotEmpty) startTime = day.activities.last.endTime;
      final endTime = _shiftTimeStr(startTime, 60);

      final newActivity = ItineraryActivityEntity(
        id: placeId,
        title: placeName,
        locationName: placeName,
        address: address ?? '',
        imageUrl: imageUrl ?? 'https://placehold.co/1080x720?text=New+Place',
        startTime: startTime,
        endTime: endTime,
        latitude: lat,
        longitude: lng,
        category: category,
      );

      return day.copyWith(activities: [...day.activities, newActivity]);
    }).toList();

    // OR-Tools tìm vị trí chèn tối ưu trong ngày
    updatedDays = await _optimizeSpecificDay(updatedDays, dayNumber);

    emit(currentState.copyWithSelected(itin.copyWith(days: updatedDays)));
  }

  /// Tổng khoảng cách Haversine của toàn bộ lộ trình (km).
  double _totalRouteDistanceKm(List<ItineraryActivityEntity> activities) {
    double total = 0;
    for (int i = 0; i < activities.length - 1; i++) {
      final a = activities[i];
      final b = activities[i + 1];
      if (a.latitude != null && a.longitude != null &&
          b.latitude != null && b.longitude != null) {
        total += _haversineKm(a.latitude!, a.longitude!, b.latitude!, b.longitude!);
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
    final a = sinDLat * sinDLat +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            sinDLng * sinDLng;
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  /// Áp dụng lộ trình được đề xuất sau khi người dùng chấp nhận.
  void applySuggestedReorder() {
    if (state is! ItineraryLoaded) return;
    final s = state as ItineraryLoaded;
    if (s.suggestedDays == null || s.selectedItinerary == null) return;
    emit(ItineraryLoaded(
      itineraries: s.itineraries,
      summary: s.summary,
      activeFilter: s.activeFilter,
      activeCompletedFilter: s.activeCompletedFilter,
      selectedItinerary: s.selectedItinerary!.copyWith(days: s.suggestedDays!),
    ));
  }

  /// Bỏ qua đề xuất sắp xếp lại.
  void dismissReorderSuggestion() {
    if (state is! ItineraryLoaded) return;
    final s = state as ItineraryLoaded;
    emit(s.copyWith(clearSuggestion: true));
  }

  Future<void> deleteActivity(String activityId) async {
    if (state is ItineraryLoaded) {
      final currentState = state as ItineraryLoaded;
      final itin = currentState.selectedItinerary;
      if (itin == null) return;

      emit(const ItineraryLoading());

      int? updatedDayNum;
      var updatedDays = itin.days.map((day) {
        final hasActivity = day.activities.any((a) => a.id == activityId);
        if (!hasActivity) return day;
        
        updatedDayNum = day.dayNumber;
        final updatedActivities = day.activities.where((a) => a.id != activityId).toList();
        return day.copyWith(activities: updatedActivities);
      }).toList();

      if (updatedDayNum != null) {
        updatedDays = await _optimizeSpecificDay(updatedDays, updatedDayNum!);
      }

      emit(currentState.copyWithSelected(itin.copyWith(days: updatedDays)));
    }
  }

  Future<List<ItineraryDayEntity>> _optimizeSpecificDay(List<ItineraryDayEntity> days, int dayNumber) async {
    final List<ItineraryDayEntity> newDays = [];
    for (final d in days) {
      if (d.dayNumber == dayNumber) {
        final optimized = await OptimizeRouteApi.optimizeDay(d.activities);
        newDays.add(d.copyWith(activities: optimized));
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
      suggestedDays: null,
      suggestedDayNumber: null,
    );
  }

  ItineraryLoaded copyWith({
    String? detailError,
    List<ItineraryDayEntity>? suggestedDays,
    int? suggestedDayNumber,
    bool clearSuggestion = false,
  }) {
    return ItineraryLoaded(
      itineraries: itineraries,
      summary: summary,
      activeFilter: activeFilter,
      activeCompletedFilter: activeCompletedFilter,
      selectedItinerary: selectedItinerary,
      detailError: detailError,
      suggestedDays: clearSuggestion ? null : (suggestedDays ?? this.suggestedDays),
      suggestedDayNumber: clearSuggestion ? null : (suggestedDayNumber ?? this.suggestedDayNumber),
    );
  }
}