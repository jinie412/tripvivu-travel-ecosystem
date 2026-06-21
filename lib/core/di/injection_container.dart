import 'package:get_it/get_it.dart';

import 'package:travel_advisor_mobile/features/city/data/datasources/city_datasource.dart';
import 'package:travel_advisor_mobile/features/city/data/repositories/city_repository_impl.dart';
import 'package:travel_advisor_mobile/features/city/domain/repositories/city_repository.dart';
import 'package:travel_advisor_mobile/features/city/domain/usecases/search_cities_usecase.dart';
import 'package:travel_advisor_mobile/features/survey/presentation/cubit/survey_cubit.dart';
import 'package:travel_advisor_mobile/features/trip_planner/domain/usecases/create_itinerary_usecase.dart';
import 'package:travel_advisor_mobile/features/trip_planner/presentation/cubit/trip_planner_cubit.dart';

import 'package:travel_advisor_mobile/core/network/dio_client.dart';
import 'package:travel_advisor_mobile/core/services/location_service.dart';
import 'package:travel_advisor_mobile/features/home/presentation/cubit/location_cubit.dart';
import 'package:travel_advisor_mobile/features/auth/data/datasources/auth_datasource.dart';
import 'package:travel_advisor_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:travel_advisor_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:travel_advisor_mobile/features/auth/domain/usecases/auth_usecases.dart';
import 'package:travel_advisor_mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:travel_advisor_mobile/features/city_detail/data/datasources/city_detail_mock_data_source.dart';
import 'package:travel_advisor_mobile/features/city_detail/data/repositories/city_detail_repository_impl.dart';
import 'package:travel_advisor_mobile/features/city_detail/domain/repositories/city_detail_repository.dart';
import 'package:travel_advisor_mobile/features/city_detail/domain/usecases/get_city_overview_usecase.dart';
import 'package:travel_advisor_mobile/features/city_detail/presentation/cubit/city_detail_cubit.dart';
import 'package:travel_advisor_mobile/features/food/data/datasources/food_remote_data_source.dart';
import 'package:travel_advisor_mobile/features/food/presentation/cubit/food_cubit.dart';
import 'package:travel_advisor_mobile/features/home/data/datasources/home_datasource.dart';
import 'package:travel_advisor_mobile/features/home/data/repositories/mock_home_repository.dart';
import 'package:travel_advisor_mobile/features/home/domain/repositories/home_repository.dart';
import 'package:travel_advisor_mobile/features/home/domain/usecases/home_usecases.dart';
import 'package:travel_advisor_mobile/features/home/presentation/cubit/explore_cubit.dart';
import 'package:travel_advisor_mobile/features/itinerary/data/datasources/itinerary_datasource.dart';
import 'package:travel_advisor_mobile/features/itinerary/data/repositories/itinerary_repository_impl.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/repositories/itinerary_repository.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/usecases/itinerary_usecases.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/cubit/itinerary_cubit.dart';
import 'package:travel_advisor_mobile/features/itinerary/tracking/data/datasources/tracking_remote_datasource.dart';
import 'package:travel_advisor_mobile/features/itinerary/tracking/data/repositories/tracking_repository_impl.dart';
import 'package:travel_advisor_mobile/features/itinerary/tracking/domain/repositories/tracking_repository.dart';
import 'package:travel_advisor_mobile/features/itinerary/tracking/domain/usecases/tracking_usecases.dart';
import 'package:travel_advisor_mobile/features/itinerary/tracking/services/geofence_tracking_service.dart';
import 'package:travel_advisor_mobile/features/itinerary/tracking/services/tracking_alarm_service.dart';
import 'package:travel_advisor_mobile/features/itinerary/tracking/presentation/cubit/tracking_cubit.dart';
import 'package:travel_advisor_mobile/features/place/data/datasources/place_datasource.dart';
import 'package:travel_advisor_mobile/features/place/data/repositories/place_repository_impl.dart';
import 'package:travel_advisor_mobile/features/place/domain/repositories/place_repository.dart';
import 'package:travel_advisor_mobile/features/place/domain/usecases/get_place_detail_usecase.dart';
import 'package:travel_advisor_mobile/features/place/presentation/cubit/place_detail_cubit.dart';
import '../../features/profile/data/datasources/profile_datasource.dart';
import 'package:travel_advisor_mobile/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:travel_advisor_mobile/features/profile/domain/repositories/profile_repository.dart';
import 'package:travel_advisor_mobile/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:travel_advisor_mobile/features/profile/domain/usecases/get_recent_activities_usecase.dart';
import 'package:travel_advisor_mobile/features/profile/domain/usecases/upload_avatar_usecase.dart';
import 'package:travel_advisor_mobile/features/profile/domain/usecases/update_profile_usecase.dart';
import 'package:travel_advisor_mobile/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:travel_advisor_mobile/features/review/data/datasources/review_datasource.dart';
import 'package:travel_advisor_mobile/features/review/data/repositories/review_repository_impl.dart';
import 'package:travel_advisor_mobile/features/review/domain/repositories/review_repository.dart';
import 'package:travel_advisor_mobile/features/review/domain/usecases/get_itinerary_for_review_usecase.dart';
import 'package:travel_advisor_mobile/features/review/presentation/cubit/review_cubit.dart';
import 'package:travel_advisor_mobile/features/saved/data/datasources/collections_datasource.dart';
import 'package:travel_advisor_mobile/features/saved/data/repositories/saved_repository_impl.dart';
import 'package:travel_advisor_mobile/features/saved/domain/repositories/saved_repository.dart';
import 'package:travel_advisor_mobile/features/saved/domain/usecases/get_favorite_itineraries_usecase.dart';
import 'package:travel_advisor_mobile/features/saved/domain/usecases/get_favorite_places_usecase.dart';
import 'package:travel_advisor_mobile/features/saved/presentation/cubit/saved_cubit.dart';
import 'package:travel_advisor_mobile/features/search/data/datasources/search_remote_datasource.dart';
import 'package:travel_advisor_mobile/features/search/data/repositories/search_repository_impl.dart';
import 'package:travel_advisor_mobile/features/search/domain/repositories/search_repository.dart';
import 'package:travel_advisor_mobile/features/search/domain/usecases/get_recent_searches.dart';
import 'package:travel_advisor_mobile/features/search/domain/usecases/search_locations.dart';
import 'package:travel_advisor_mobile/features/search/domain/usecases/search_all_usecase.dart';
import 'package:travel_advisor_mobile/features/search/domain/usecases/search_by_type_usecase.dart';
import 'package:travel_advisor_mobile/features/search/presentation/cubit/search_cubit.dart';
import 'package:travel_advisor_mobile/features/search/presentation/cubit/search_all_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travel_advisor_mobile/features/search/data/datasources/search_local_datasource.dart';
import 'package:travel_advisor_mobile/features/search/domain/usecases/save_recent_search.dart';
import 'package:travel_advisor_mobile/features/home/data/datasources/notification_datasource.dart';
import 'package:travel_advisor_mobile/features/home/data/repositories/notification_repository_impl.dart';
import 'package:travel_advisor_mobile/features/home/domain/repositories/notification_repository.dart';
import 'package:travel_advisor_mobile/features/home/domain/usecases/notification_usecases.dart';
import 'package:travel_advisor_mobile/features/home/presentation/cubit/notification_cubit.dart';

final sl = GetIt.instance;

/// 🔌 Single registration point for all dependencies.
Future<void> initDependencies() async {
  // ── Network ────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<DioClient>(() => DioClient());

  // ── Location (vị trí hiện tại + reverse geocoding) ───────────────────────────
  sl.registerLazySingleton<LocationService>(() => LocationService());
  sl.registerFactory(() => LocationCubit(sl()));

  // ── Auth ───────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthDataSource>(() => RemoteAuthDataSource(sl()));
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));

  // Đăng ký các UseCase
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterTouristUseCase(sl()));
  sl.registerLazySingleton(() => ForgotPasswordUseCase(sl()));
  sl.registerLazySingleton(() => UpdatePasswordUseCase(sl()));
  sl.registerLazySingleton(() => ChangePasswordUseCase(sl()));
  sl.registerLazySingleton(() => LoginWithGoogleUseCase(sl()));

  // Đăng ký Cubit
  sl.registerFactory(
    () => AuthCubit(
      loginUseCase: sl(),
      registerTouristUseCase: sl(),
      forgotPasswordUseCase: sl(),
      updatePasswordUseCase: sl(),
      changePasswordUseCase: sl(),
      loginWithGoogleUseCase: sl(),
    ),
  );

  // ── Home ───────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<HomeDataSource>(() => RemoteHomeDataSource(sl()));
  sl.registerLazySingleton<HomeRepository>(() => HomeRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetExploreHomeUseCase(sl()));
  sl.registerLazySingleton(() => GetRestaurantsUseCase(sl()));
  sl.registerLazySingleton(() => GetPublicSuggestionsUseCase(sl()));
  sl.registerLazySingleton(() => GetFeaturedDestinationsUseCase(sl()));
  sl.registerLazySingleton(() => GetRestaurantsByCategoriesUseCase(sl()));
  sl.registerLazySingleton(() => GetHotelsByCategoriesUseCase(sl()));
  sl.registerFactory(
    () => ExploreCubit(
      getExploreHome: sl(),
      getPublicSuggestions: sl(),
      getFeaturedDestinations: sl(),
      getRestaurantsByCategories: sl(),
      getHotelsByCategories: sl(),
    ),
  );
  
    // ── Notifications ─────────────────────────────────────────────────────────
    sl.registerLazySingleton<NotificationDataSource>(() => RemoteNotificationDataSource(sl()));
    sl.registerLazySingleton<NotificationRepository>(() => NotificationRepositoryImpl(sl()));
    sl.registerLazySingleton(() => GetNotificationsUseCase(sl()));
    sl.registerFactory(
      () => NotificationCubit(getNotifications: sl()),
    );

  // ── Itinerary ──────────────────────────────────────────────────────────────
  sl.registerLazySingleton<ItineraryDataSource>(
    () => RemoteItineraryDataSource(),//MockItineraryDataSource(),
    // TODO: swap → RemoteItineraryDataSource(sl<DioClient>())
  );
  sl.registerLazySingleton<ItineraryRepository>(
    () => ItineraryRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetItinerariesUseCase(sl()));
  sl.registerLazySingleton(() => GetItinerarySummaryUseCase(sl()));
  sl.registerLazySingleton(() => DeleteItineraryUseCase(sl()));
  sl.registerLazySingleton(() => GetItineraryDetailUseCase(sl()));
  sl.registerLazySingleton(() => UpdateItineraryActivitiesUseCase(sl()));
  sl.registerLazySingleton(() => ToggleVisibilityUseCase(sl()));
  sl.registerLazySingleton(() => UpdateItineraryTitleUseCase(sl()));
  sl.registerLazySingleton(() => UpdateActivityUseCase(sl()));
  sl.registerLazySingleton(() => DeleteActivityUseCase(sl()));
  sl.registerFactory(
    () => ItineraryCubit(
      getItineraries: sl(),
      getSummary: sl(),
      deleteItinerary: sl(),
      getItineraryDetail: sl(),
      updateActivities: sl(),
      updateTitle: sl(),
    ),
  );

  // ── Itinerary Tracking (geofence + dwell) ───────────────────────────────────
  sl.registerLazySingleton<TrackingRemoteDataSource>(
    () => TrackingRemoteDataSource(sl<DioClient>()),
  );
  sl.registerLazySingleton<TrackingRepository>(
    () => TrackingRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => StartTrackingUseCase(sl()));
  sl.registerLazySingleton(() => GetGeofencesUseCase(sl()));
  sl.registerLazySingleton(() => SendTrackingEventUseCase(sl()));
  sl.registerLazySingleton(() => ManualCheckInUseCase(sl()));
  sl.registerLazySingleton(() => GetTrackingStatusUseCase(sl()));
  sl.registerLazySingleton(() => EndTrackingDayUseCase(sl()));
  sl.registerLazySingleton<GeofenceTrackingService>(
    () => GeofenceTrackingService(),
  );
  sl.registerLazySingleton<TrackingAlarmService>(() => TrackingAlarmService());
  sl.registerFactory(
    () => TrackingCubit(
      start: sl(),
      status: sl(),
      sendEvent: sl(),
      checkIn: sl(),
      endDay: sl(),
      geofenceSvc: sl(),
      alarmSvc: sl(),
    ),
  );

  // ── Profile ────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<ProfileDataSource>(() => RemoteProfileDataSource(sl()));
  sl.registerLazySingleton<ProfileRepository>(() => ProfileRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetProfileUseCase(sl()));
  sl.registerLazySingleton(() => GetRecentActivitiesUseCase(sl()));
  sl.registerLazySingleton(() => UploadAvatarUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProfileUseCase(sl()));
  sl.registerFactory(
    () => ProfileCubit(
      getProfile: sl(),
      getRecentActivities: sl(),
      uploadAvatar: sl(),
      updateProfile: sl(),
    ),
  );

  // ── Review ─────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<ReviewDataSource>(() => RemoteReviewDataSource(sl()));
  sl.registerLazySingleton<ReviewRepository>(() => ReviewRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetItineraryForReviewUseCase(sl()));
  sl.registerFactory(
    () => ReviewCubit(getItineraryForReview: sl(), reviewRepository: sl()),
  );
// Trong hàm initDependencies(), thêm SharedPreferences ở phần đầu (trước tất cả features):
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  // ── Search ─────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<SearchRemoteDataSource>(
    () => SearchRemoteDataSourceImpl(dioClient: sl<DioClient>()),
  );

  sl.registerLazySingleton<SearchLocalDataSource>(
    () => SearchLocalDataSourceImpl(sharedPreferences: sl<SharedPreferences>()),
  );
  sl.registerLazySingleton<SearchRepository>(
    () => SearchRepositoryImpl(
      remoteDataSource: sl<SearchRemoteDataSource>(),
      localDataSource: sl<SearchLocalDataSource>(),
    ),
  );
  sl.registerLazySingleton(() => GetRecentSearches(sl()));
  sl.registerLazySingleton(() => SearchLocations(sl()));
  sl.registerLazySingleton(() => SaveRecentSearch(sl()));
  sl.registerLazySingleton(() => SearchAllUseCase(sl()));
  sl.registerLazySingleton(() => SearchByTypeUseCase(sl()));
  sl.registerFactory(() => SearchCubit(sl(), sl(), sl())); // GetRecentSearches, SearchLocations, SaveRecentSearch
  sl.registerFactory(() => SearchAllCubit(sl()));

  // ── City Detail ────────────────────────────────────────────────────────────
  sl.registerLazySingleton<CityDetailDataSource>(() => RemoteCityDetailDataSource(sl()));
  sl.registerLazySingleton<CityDetailRepository>(() => CityDetailRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetCityOverviewUseCase(sl()));
  sl.registerFactory(() => CityDetailCubit(sl()));

  // ── Food / Orders ─────────────────────────────────────────────────────────
  sl.registerLazySingleton<FoodRemoteDataSource>(() => FoodRemoteDataSource(sl()));
  sl.registerFactory(() => FoodCubit(remote: sl()));

  // ── Place ──────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<PlaceDataSource>(() => RemotePlaceDataSource(sl()));
  sl.registerLazySingleton<PlaceRepository>(() => PlaceRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetPlaceDetailUseCase(sl()));
  sl.registerFactory(() => PlaceDetailCubit(getPlaceDetailUseCase: sl()));

  // ── Saved ──────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<CollectionsDataSource>(
    () => RemoteCollectionsDataSource(sl()),
  );
  sl.registerLazySingleton<SavedRepository>(
    () => SavedRepositoryImpl(dataSource: sl()),
  );
  sl.registerLazySingleton(() => GetFavoriteItinerariesUseCase(repository: sl()));
  sl.registerLazySingleton(() => GetFavoritePlacesUseCase(repository: sl()));
  sl.registerFactory(
    () => SavedCubit(
      getFavoriteItinerariesUseCase: sl(),
      getFavoritePlacesUseCase: sl(),
    ),
  );

  // ── City ──────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<CityDataSource>(() => RemoteCityDataSource(sl()));
  sl.registerLazySingleton<CityRepository>(() => CityRepositoryImpl(sl()));
  sl.registerLazySingleton(() => SearchCitiesUseCase(sl()));

  // ── Trip Planner ───────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => CreateItineraryUseCase(sl()));
  sl.registerFactory(() => TripPlannerCubit(createItinerary: sl()));

  // ── Survey ─────────────────────────────────────────────────────────────────
  sl.registerFactory(() => SurveyCubit());
}
