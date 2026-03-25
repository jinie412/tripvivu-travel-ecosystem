import 'package:get_it/get_it.dart';

import '../../features/trip_planner/presentation/cubit/trip_planner_cubit.dart';
import '../../features/survey/presentation/cubit/survey_cubit.dart';

import '../../features/auth/data/datasources/auth_datasource.dart';
import '../../features/auth/data/repositories/mock_auth_repository.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/auth_usecases.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/home/data/datasources/home_datasource.dart';
import '../../features/home/data/repositories/mock_home_repository.dart';
import '../../features/home/domain/repositories/home_repository.dart';
import '../../features/home/domain/usecases/home_usecases.dart';
import '../../features/home/presentation/cubit/explore_cubit.dart';
import '../../features/itinerary/data/datasources/itinerary_datasource.dart';
import '../../features/itinerary/data/repositories/itinerary_repository_impl.dart';
import '../../features/itinerary/domain/repositories/itinerary_repository.dart';
import '../../features/itinerary/domain/usecases/itinerary_usecases.dart';
import '../../features/itinerary/presentation/cubit/itinerary_cubit.dart';
import '../../features/profile/data/datasources/profile_datasource.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/domain/usecases/get_profile_usecase.dart';
import '../../features/profile/domain/usecases/get_recent_activities_usecase.dart';
import '../../features/profile/presentation/cubit/profile_cubit.dart';
import '../../features/review/data/datasources/review_datasource.dart';
import '../../features/review/data/repositories/review_repository_impl.dart';
import '../../features/review/domain/repositories/review_repository.dart';
import '../../features/review/domain/usecases/get_itinerary_for_review_usecase.dart';
import '../../features/review/presentation/cubit/review_cubit.dart';
import '../../features/search/data/datasources/search_mock_data_source.dart';
import '../../features/search/data/repositories/search_repository_impl.dart';
import '../../features/search/domain/repositories/search_repository.dart';
import '../../features/search/domain/usecases/get_recent_searches.dart';
import '../../features/search/domain/usecases/search_locations.dart';
import '../../features/search/presentation/cubit/search_cubit.dart';
import '../../features/city_detail/data/datasources/city_detail_mock_data_source.dart';
import '../../features/city_detail/data/repositories/city_detail_repository_impl.dart';
import '../../features/city_detail/domain/repositories/city_detail_repository.dart';
import '../../features/city_detail/domain/usecases/get_city_overview_usecase.dart';
import '../../features/city_detail/presentation/cubit/city_detail_cubit.dart';
import '../../features/place/data/datasources/place_datasource.dart';
import '../../features/place/data/repositories/place_repository_impl.dart';
import '../../features/place/domain/repositories/place_repository.dart';
import '../../features/place/domain/usecases/get_place_detail_usecase.dart';
import '../../features/place/presentation/cubit/place_detail_cubit.dart';
import '../../features/saved/data/datasources/saved_mock_data_source.dart';
import '../../features/saved/data/repositories/saved_repository_impl.dart';
import '../../features/saved/domain/repositories/saved_repository.dart';
import '../../features/saved/presentation/cubit/saved_cubit.dart';
import '../network/dio_client.dart';

final sl = GetIt.instance;

/// 🔌 Single registration point for all dependencies.
Future<void> initDependencies() async {
  // ── Network ────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<DioClient>(() => DioClient());

  // ── Auth ───────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthDataSource>(() => MockAuthDataSource());
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerFactory(
    () => AuthCubit(loginUseCase: sl(), registerUseCase: sl()),
  );

  // ── Home ───────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<HomeDataSource>(() => MockHomeDataSource());
  sl.registerLazySingleton<HomeRepository>(() => HomeRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetSuggestionsUseCase(sl()));
  sl.registerLazySingleton(() => GetDestinationsUseCase(sl()));
  sl.registerLazySingleton(() => GetHotelsUseCase(sl()));
  sl.registerLazySingleton(() => GetRestaurantsUseCase(sl()));
  sl.registerFactory(
    () => ExploreCubit(
      getSuggestions: sl(),
      getDestinations: sl(),
      getHotels: sl(),
      getRestaurants: sl(),
      getItineraries: sl(),
    ),
  );

  // ── Itinerary ──────────────────────────────────────────────────────────────
  sl.registerLazySingleton<ItineraryDataSource>(() => MockItineraryDataSource());
  sl.registerLazySingleton<ItineraryRepository>(() => ItineraryRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetItinerariesUseCase(sl()));
  sl.registerLazySingleton(() => GetItinerarySummaryUseCase(sl()));
  sl.registerLazySingleton(() => DeleteItineraryUseCase(sl()));
  sl.registerLazySingleton(() => GetItineraryDetailUseCase(sl()));
  sl.registerFactory(
    () => ItineraryCubit(
      getItineraries: sl(),
      getSummary: sl(),
      deleteItinerary: sl(),
      getItineraryDetail: sl(),
    ),
  );

  // ── Profile ────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<ProfileDataSource>(() => MockProfileDataSource());
  sl.registerLazySingleton<ProfileRepository>(() => ProfileRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetProfileUseCase(sl()));
  sl.registerLazySingleton(() => GetRecentActivitiesUseCase(sl()));
  sl.registerFactory(
    () => ProfileCubit(
      getProfile: sl(),
      getRecentActivities: sl(),
    ),
  );

  // ── Review ─────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<ReviewDataSource>(() => MockReviewDataSource());
  sl.registerLazySingleton<ReviewRepository>(() => ReviewRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetItineraryForReviewUseCase(sl()));
  sl.registerFactory(
    () => ReviewCubit(getItineraryForReview: sl()),
  );

  // ── Search ─────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<SearchMockDataSource>(() => SearchMockDataSourceImpl());
  sl.registerLazySingleton<SearchRepository>(
    () => SearchRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetRecentSearches(sl()));
  sl.registerLazySingleton(() => SearchLocations(sl()));
  sl.registerFactory(() => SearchCubit(sl(), sl()));

  // ── City Detail ────────────────────────────────────────────────────────────
  sl.registerLazySingleton<CityDetailDataSource>(() => CityDetailMockDataSource());
  sl.registerLazySingleton<CityDetailRepository>(() => CityDetailRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetCityOverviewUseCase(sl()));
  sl.registerFactory(() => CityDetailCubit(sl()));

  // ── Place ──────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<PlaceDataSource>(() => MockPlaceDataSource());
  sl.registerLazySingleton<PlaceRepository>(() => PlaceRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetPlaceDetailUseCase(sl()));
  sl.registerFactory(
    () => PlaceDetailCubit(getPlaceDetailUseCase: sl()),
  );

  // ── Saved ──────────────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => SavedMockDataSource());
  sl.registerLazySingleton<SavedRepository>(
    () => SavedRepositoryImpl(dataSource: sl<SavedMockDataSource>()),
  );
  sl.registerFactory(() => SavedCubit(repository: sl()));

  // ── Trip Planner ───────────────────────────────────────────────────────────
  sl.registerFactory(() => TripPlannerCubit());

  // ── Survey ─────────────────────────────────────────────────────────────────
  sl.registerFactory(() => SurveyCubit());
}
