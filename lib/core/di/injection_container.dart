import 'package:get_it/get_it.dart';

import 'package:travel_advisor_mobile/features/survey/presentation/cubit/survey_cubit.dart';
import 'package:travel_advisor_mobile/features/trip_planner/presentation/cubit/trip_planner_cubit.dart';

import 'package:travel_advisor_mobile/core/network/dio_client.dart';
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
import 'package:travel_advisor_mobile/features/place/data/datasources/place_datasource.dart';
import 'package:travel_advisor_mobile/features/place/data/repositories/place_repository_impl.dart';
import 'package:travel_advisor_mobile/features/place/domain/repositories/place_repository.dart';
import 'package:travel_advisor_mobile/features/place/domain/usecases/get_place_detail_usecase.dart';
import 'package:travel_advisor_mobile/features/place/presentation/cubit/place_detail_cubit.dart';
import 'package:travel_advisor_mobile/features/profile/data/datasources/profile_datasource.dart';
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
import 'package:travel_advisor_mobile/features/saved/data/datasources/saved_mock_data_source.dart';
import 'package:travel_advisor_mobile/features/saved/data/repositories/saved_repository_impl.dart';
import 'package:travel_advisor_mobile/features/saved/domain/repositories/saved_repository.dart';
import 'package:travel_advisor_mobile/features/saved/presentation/cubit/saved_cubit.dart';
import 'package:travel_advisor_mobile/features/search/data/datasources/search_mock_data_source.dart';
import 'package:travel_advisor_mobile/features/search/data/repositories/search_repository_impl.dart';
import 'package:travel_advisor_mobile/features/search/domain/repositories/search_repository.dart';
import 'package:travel_advisor_mobile/features/search/domain/usecases/get_recent_searches.dart';
import 'package:travel_advisor_mobile/features/search/domain/usecases/search_locations.dart';
import 'package:travel_advisor_mobile/features/search/presentation/cubit/search_cubit.dart';

final sl = GetIt.instance;

/// 🔌 Single registration point for all dependencies.
Future<void> initDependencies() async {
  // ── Network ────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<DioClient>(() => DioClient());

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
  sl.registerFactory(
    () => ItineraryCubit(
      getItineraries: sl(),
      getSummary: sl(),
      deleteItinerary: sl(),
      getItineraryDetail: sl(),
    ),
  );

  // ── Profile ────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<ProfileDataSource>(
    () => RemoteProfileDataSource(sl()),
  );
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(sl()),
  );
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
  sl.registerLazySingleton<ReviewDataSource>(() => MockReviewDataSource());
  sl.registerLazySingleton<ReviewRepository>(() => ReviewRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetItineraryForReviewUseCase(sl()));
  sl.registerFactory(() => ReviewCubit(getItineraryForReview: sl()));

  // ── Search ─────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<SearchMockDataSource>(
    () => SearchMockDataSourceImpl(),
  );
  sl.registerLazySingleton<SearchRepository>(
    () => SearchRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetRecentSearches(sl()));
  sl.registerLazySingleton(() => SearchLocations(sl()));
  sl.registerFactory(() => SearchCubit(sl(), sl()));

  // ── City Detail ────────────────────────────────────────────────────────────
  sl.registerLazySingleton<CityDetailDataSource>(
    () => CityDetailMockDataSource(),
  );
  sl.registerLazySingleton<CityDetailRepository>(
    () => CityDetailRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetCityOverviewUseCase(sl()));
  sl.registerFactory(() => CityDetailCubit(sl()));

  // ── Place ──────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<PlaceDataSource>(() => MockPlaceDataSource());
  sl.registerLazySingleton<PlaceRepository>(() => PlaceRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetPlaceDetailUseCase(sl()));
  sl.registerFactory(() => PlaceDetailCubit(getPlaceDetailUseCase: sl()));

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
