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

/// Cubit quản lý trạng thái màn hình "Lịch trình của tôi".
///
/// Luồng:
///   1. [loadData]   → emit Loading → gọi UseCases → emit Loaded / Error
///   2. [filterBy]   → emit Loading → gọi lại với status filter → emit Loaded
///   3. [deleteItem] → xóa → tải lại danh sách
class ItineraryCubit extends Cubit<ItineraryState> {
  final GetItinerariesUseCase _getItineraries;
  final GetItinerarySummaryUseCase _getSummary;
  final DeleteItineraryUseCase _deleteItinerary;
  final GetItineraryDetailUseCase _getItineraryDetail;

  /// Filter đang active, null = "Tất cả".
  ItineraryStatus? _currentFilter;

  /// Filter con cho "Đã đi".
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

  /// 🔧 CHẾ ĐỘ DEMO: Set true để bỏ qua lỗi Backend và dùng dữ liệu mẫu
  static const bool kDemoMode = AppConfig.kUseMockData;

  /// Tải toàn bộ dữ liệu (danh sách + thống kê).
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
        // ⚠️ BACKEND NOTE: Khối này chỉ dùng để chỉnh giao diện khi chưa có API
        final mockSummary = const ItinerarySummary(total: 5, draft: 2, upcoming: 1, completed: 1);
        final mockItineraries = [
          ItineraryEntity(
            id: 'mock_completed', title: 'Hành trình di sản Miền Trung', 
            startDate: DateTime.now().subtract(const Duration(days: 10)), 
            endDate: DateTime.now().subtract(const Duration(days: 5)),
            status: ItineraryStatus.completed, progress: 1.0, estimatedCost: 15000000,
            rating: null,
            visitedLocations: 12,
            totalLocations: 12,
          ),
          ItineraryEntity(
            id: 'mock_ongoing', title: 'Phú Quốc Hè 2024', 
            startDate: DateTime.now().subtract(const Duration(days: 1)), 
            endDate: DateTime.now().add(const Duration(days: 3)),
            status: ItineraryStatus.ongoing, progress: 0.8, estimatedCost: 8500000,
            visitedLocations: 10,
            totalLocations: 12,
          ),
          ItineraryEntity(
            id: 'mock_draft', title: 'Sapa Mùa Lúa Chín', 
            status: ItineraryStatus.draft, estimatedCost: 5200000
          ),
        ];
        emit(ItineraryLoaded(
          itineraries: mockItineraries, summary: mockSummary,
          activeFilter: _currentFilter, activeCompletedFilter: _currentCompletedFilter,
          selectedItinerary: (state is ItineraryLoaded) ? (state as ItineraryLoaded).selectedItinerary : null,
        ));
      } else {
        // 🚀 BACKEND: Dòng gốc sẽ chạy khi kDemoMode = false
        emit(ItineraryError(e.toString()));
      }
    }
  }

  /// Lọc theo trạng thái...
  Future<void> filterBy(ItineraryStatus? status) async {
    _currentFilter = status;
    _currentCompletedFilter = CompletedFilter.all;
    await loadData();
  }

  /// Lọc con cho "Đã đi"...
  Future<void> filterByCompleted(CompletedFilter filter) async {
    _currentCompletedFilter = filter;
    await loadData();
  }

  /// Xóa một lịch trình...
  Future<void> deleteItem(String id) async {
    try {
      await _deleteItinerary(id);
      await loadData();
    } catch (e) {
      emit(ItineraryError('Không thể xóa lịch trình: ${e.toString()}'));
    }
  }

  /// Chọn một lịch trình để xem chi tiết.
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
          // ⚠️ BACKEND NOTE: Mock detail cho Demo
          final mockDetail = ItineraryDetailEntity(
            id: id, 
            title: 'Chi tiết lịch trình Demo', 
            destination: 'Phú Quốc',
            startDate: DateTime.now(), 
            endDate: DateTime.now().add(const Duration(days: 3)),
            status: 'PLANNING', durationDays: 4, activitiesCount: 12, 
            visitedLocations: 10, totalLocations: 12,
            hotelsCount: 1, transportTurns: 4,
            estimatedBudget: 8500000, spentBudget: 0, currency: 'VNĐ', days: [], notes: ['Lưu ý 1'], visitedRestaurants: [],
          );
          emit((state as ItineraryLoaded).copyWithSelected(_materializeMockDays(mockDetail)));
        } else {
          emit(ItineraryError('Không thể tải chi tiết: ${e.toString()}'));
        }
      }
    } else {
      emit(const ItineraryLoading());
      try {
        final results = await Future.wait([_getSummary(), _getItineraryDetail(id), _getItineraries()]);
        final materializedDetail = _materializeMockDays(results[1] as ItineraryDetailEntity);
        emit(ItineraryLoaded(
          itineraries: results[2] as List<ItineraryEntity>,
          summary: results[0] as ItinerarySummary,
          selectedItinerary: materializedDetail,
        ));
      } catch (e) {
        emit(ItineraryError('Không thể tải dữ liệu: ${e.toString()}'));
      }
    }
  }

  ItineraryDetailEntity _materializeMockDays(ItineraryDetailEntity itin) {
    if (itin.days.length >= 3) return itin;

    final List<ItineraryDayEntity> displayDays = List.from(itin.days);
    final firstDayDate = displayDays.isNotEmpty ? displayDays.first.date : DateTime.now();

    final mockActivitiesDay1 = [
      ItineraryActivityEntity(
        id: 'mock_1_1',
        title: 'Dinh Độc Lập',
        locationName: 'Dinh Độc Lập',
        address: '135 Nam Kỳ Khởi Nghĩa, Bến Nghé, Quận 1',
        startTime: '08:30',
        endTime: '10:30',
        imageUrl: 'https://images.unsplash.com/photo-1559506825-f933e38714eb?w=600&q=80',
        transportInfo: 'Địa điểm xuất phát',
        rating: DemoReviewStore.getLocationRating('mock_1_1') ?? 4.5,
        reviewCount: 15600,
        price: 60000,
        status: ActivityStatus.daDi,
      ),
      ItineraryActivityEntity(
        id: 'mock_1_2',
        title: 'Nhà thờ Đức Bà & Bưu điện TP',
        locationName: 'Công xã Paris',
        address: 'Số 1 Công xã Paris, Bến Nghé, Quận 1',
        startTime: '11:00',
        endTime: '12:00',
        imageUrl: 'https://images.unsplash.com/photo-1583417319070-4a69db38a482?w=600&q=80',
        transportInfo: '10 phút đi bộ',
        rating: DemoReviewStore.getLocationRating('mock_1_2') ?? 4.8,
        reviewCount: 42000,
        isFree: true,
        status: ActivityStatus.daDi,
      ),
      ItineraryActivityEntity(
        id: 'mock_1_3',
        title: 'Ăn trưa Cơm tấm Ba Ghiền',
        locationName: 'Đặc sản Sài Gòn',
        address: '84 Đặng Văn Ngữ, Phú Nhuận',
        startTime: '12:30',
        endTime: '14:00',
        imageUrl: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=600&q=80',
        transportInfo: '15 phút di chuyển',
        rating: 4.4,
        reviewCount: 3800,
        price: 85000,
      ),
      ItineraryActivityEntity(
        id: 'mock_1_4',
        title: 'Bảo tàng Chứng tích Chiến tranh',
        locationName: 'Bảo tàng CTCT',
        address: '28 Võ Văn Tần, Quận 3',
        startTime: '14:30',
        endTime: '16:30',
        imageUrl: 'https://images.unsplash.com/photo-1599708153386-62e200399066?w=600&q=80',
        transportInfo: '10 phút di chuyển',
        rating: 4.6,
        reviewCount: 18400,
        price: 40000,
      ),
      ItineraryActivityEntity(
        id: 'mock_1_5',
        title: 'Phố đi bộ Nguyễn Huệ',
        locationName: 'Quận 1',
        address: 'Nguyễn Huệ, Quận 1',
        startTime: '19:00',
        endTime: '21:00',
        imageUrl: 'https://images.unsplash.com/photo-1528127269322-539801943592?w=600&q=80',
        transportInfo: 'Tự do dạo phố',
        rating: 4.7,
        reviewCount: 52000,
        isFree: true,
      ),
    ];

    final mockActivitiesDay2 = [
      ItineraryActivityEntity(
        id: 'mock_2_1',
        title: 'Bảo tàng Mỹ thuật TP.HCM',
        locationName: 'Quận 1',
        address: '97 Pho Duc Chinh, Quận 1',
        startTime: '09:00',
        endTime: '11:00',
        imageUrl: 'https://images.unsplash.com/photo-1579783902614-a3fb3927b6a5?w=600&q=80',
        transportInfo: '15 phút di chuyển',
        rating: 4.7,
        reviewCount: 6500,
        price: 30000,
      ),
      ItineraryActivityEntity(
        id: 'mock_2_2',
        title: 'Landmark 81 Skyview',
        locationName: 'Vinhomes Central Park',
        address: '208 Nguyễn Hữu Cảnh, Bình Thạnh',
        startTime: '14:30',
        endTime: '17:00',
        imageUrl: 'https://images.unsplash.com/photo-1559592471-744e99c1586e?w=600&q=80',
        transportInfo: '20 phút di chuyển',
        rating: 4.7,
        reviewCount: 8900,
        price: 420000,
      ),
      ItineraryActivityEntity(
        id: 'mock_2_3',
        title: 'Du thuyền sông Sài Gòn',
        locationName: 'Bến Bạch Đằng',
        address: 'Số 10B Tôn Đức Thắng, Quận 1',
        startTime: '18:00',
        endTime: '20:00',
        imageUrl: 'https://images.unsplash.com/photo-1565299507177-b0ac967c507c?w=600&q=80',
        transportInfo: 'Ngắm hoàng hôn',
        rating: 4.6,
        reviewCount: 3200,
        price: 250000,
      ),
    ];

    final mockActivitiesDay3 = [
      ItineraryActivityEntity(
        id: 'mock_3_1',
        title: 'Chùa Bà Thiên Hậu',
        locationName: 'Chợ Lớn',
        address: '710 Nguyễn Trãi, Quận 5',
        startTime: '08:30',
        endTime: '10:30',
        imageUrl: 'https://images.unsplash.com/photo-1528127269322-539801943592?w=600&q=80',
        transportInfo: '15 phút di chuyển',
        rating: 4.7,
        reviewCount: 5600,
        isFree: true,
      ),
      ItineraryActivityEntity(
        id: 'mock_3_2',
        title: 'Chợ Bến Thành',
        locationName: 'Quận 1',
        address: 'Công trường Quách Thị Trang, Quận 1',
        startTime: '11:00',
        endTime: '13:00',
        imageUrl: 'https://images.unsplash.com/photo-1571474004502-c1def214ac6d?w=600&q=80',
        transportInfo: 'Mua sắm đặc sản',
        rating: 4.2,
        reviewCount: 28000,
        isFree: true,
      ),
    ];

    // Tạo dữ liệu cho Day 1 nếu rỗng
    if (displayDays.isEmpty) {
      displayDays.add(ItineraryDayEntity(
        dayNumber: 1,
        date: firstDayDate,
        temperature: 31,
        totalDuration: '12 giờ 30 phút',
        locationsCount: mockActivitiesDay1.length,
        dayBudget: 185000.0,
        activities: mockActivitiesDay1,
      ));
    }

    // Đắp thêm các ngày còn thiếu đến đủ 3 ngày
    for (int i = displayDays.length + 1; i <= 3; i++) {
      final activities = i == 2 ? mockActivitiesDay2 : mockActivitiesDay3;
      final budget = i == 2 ? 700000.0 : 0.0;
      final duration = i == 2 ? '11 giờ 00 phút' : '4 giờ 30 phút';

      displayDays.add(ItineraryDayEntity(
        dayNumber: i,
        date: firstDayDate.add(Duration(days: i - 1)),
        temperature: 30 + (i % 3),
        totalDuration: duration,
        locationsCount: activities.length,
        dayBudget: budget,
        activities: activities,
      ));
    }

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

  /// Cập nhật thời gian trực tiếp (UI Only theo yêu cầu).
  void updateActivityTime(String activityId, {String? startTime, String? endTime}) {
    if (state is ItineraryLoaded) {
      final currentState = state as ItineraryLoaded;
      final itin = currentState.selectedItinerary;
      if (itin == null) return;

      // Tạo bản sao mới của Itinerary với activity đã được cập nhật
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

  /// Cập nhật đánh giá cho một hoạt động cụ thể
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