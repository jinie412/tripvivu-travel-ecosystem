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

class ItineraryCubit extends Cubit<ItineraryState> {
  final GetItinerariesUseCase _getItineraries;
  final GetItinerarySummaryUseCase _getSummary;
  final DeleteItineraryUseCase _deleteItinerary;
  final GetItineraryDetailUseCase _getItineraryDetail;

  ItineraryStatus? _currentFilter;
  CompletedFilter _currentCompletedFilter = CompletedFilter.all;

  ItineraryCubit({
    required GetItinerariesUseCase getItineraries,
    required GetItinerarySummaryUseCase getSummary,
    required DeleteItineraryUseCase deleteItinerary,
    required GetItineraryDetailUseCase getItineraryDetail,
  })  : _getItineraries = getItineraries,
        _getSummary = getSummary,
        _deleteItinerary = deleteItinerary,
        _getItineraryDetail = getItineraryDetail,
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
          final mockDetail = ItineraryDetailEntity(
            id: id, title: 'Đà Nẵng - Thành phố đáng sống', 
            destination: 'Đà Nẵng',
            startDate: DateTime.now(), endDate: DateTime.now().add(const Duration(days: 3)),
            status: 'ONGOING', durationDays: 3, activitiesCount: 5, 
            visitedLocations: 2, totalLocations: 5,
            hotelsCount: 1, transportTurns: 3,
            estimatedBudget: 4500000, spentBudget: 1200000, currency: 'VNĐ', days: [], notes: [], visitedRestaurants: [],
            centerCoordinate: [16.0611, 108.2274],
          );
          emit((state as ItineraryLoaded).copyWithSelected(_materializeMockDays(mockDetail)));
        } else {
          emit(ItineraryError('Không thể tải chi tiết: ${e.toString()}'));
        }
      }
    }
  }

  ItineraryDetailEntity _materializeMockDays(ItineraryDetailEntity itin) {
    if (itin.days.length >= 1) return itin;

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
        transportInfo: '5 phút đi bộ (300m)',
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
        transportInfo: '3 phút đi bộ (200m)',
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
        transportInfo: '10 phút đi bộ (600m)',
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
        transportInfo: '5 phút đi bộ (400m)',
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

    return itin.copyWith(days: displayDays);
  }

  void toggleItineraryStatus(String id, bool isOngoing) {
    if (state is ItineraryLoaded) {
      final currentState = state as ItineraryLoaded;
      final updatedList = currentState.itineraries.map((itinerary) {
        if (itinerary.id == id) {
          return itinerary.copyWith(
            status: isOngoing ? ItineraryStatus.ongoing : ItineraryStatus.upcoming,
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

  void updateActivityTime(String activityId, {String? startTime, String? endTime}) {
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
}

extension on ItineraryLoaded {
  ItineraryLoaded copyWithSelected(dynamic selected) {
    return ItineraryLoaded(
      itineraries: itineraries,
      summary: summary,
      activeFilter: activeFilter,
      activeCompletedFilter: activeCompletedFilter,
      selectedItinerary: selected,
    );
  }
}