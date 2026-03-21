import 'package:get_it/get_it.dart';

import '../../features/trip_planner/presentation/cubit/trip_planner_cubit.dart';

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
import '../../features/place/data/datasources/place_datasource.dart';
import '../../features/place/data/repositories/place_repository_impl.dart';
import '../../features/place/domain/repositories/place_repository.dart';
import '../../features/place/domain/usecases/get_place_detail_usecase.dart';
import '../../features/place/presentation/cubit/place_detail_cubit.dart';
import '../network/dio_client.dart';

final sl = GetIt.instance;

/// 🔌 Single registration point for all dependencies.
///
/// TO SWITCH TO REAL BACKEND, change only the DataSource lines:
///   MockAuthDataSource()      → RemoteAuthDataSource(`sl<DioClient>()`)
///   MockHomeDataSource()      → RemoteHomeDataSource(`sl<DioClient>()`)
///   MockItineraryDataSource() → RemoteItineraryDataSource(`sl<DioClient>()`)
Future<void> initDependencies() async {
  // ── Network ────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<DioClient>(() => DioClient());

  // ── Auth DataSources ───────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthDataSource>(
    () => MockAuthDataSource(),
    // TODO: swap → RemoteAuthDataSource(sl<DioClient>())
  );

  // ── Auth Repository ────────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl<AuthDataSource>()),
  );

  // ── Auth UseCases ──────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => LoginUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => RegisterUseCase(sl<AuthRepository>()));

  // ── Auth Cubit (factory = new instance per screen) ─────────────────────────
  sl.registerFactory(
    () => AuthCubit(
      loginUseCase: sl<LoginUseCase>(),
      registerUseCase: sl<RegisterUseCase>(),
    ),
  );

  // ── Home DataSources ───────────────────────────────────────────────────────
  sl.registerLazySingleton<HomeDataSource>(
    () => MockHomeDataSource(),
    // TODO: swap → RemoteHomeDataSource(sl<DioClient>())
  );

  // ── Home Repository ────────────────────────────────────────────────────────
  sl.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(sl<HomeDataSource>()),
  );

  // ── Home UseCases ──────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => GetSuggestionsUseCase(sl<HomeRepository>()));
  sl.registerLazySingleton(
      () => GetDestinationsUseCase(sl<HomeRepository>()));
  sl.registerLazySingleton(() => GetHotelsUseCase(sl<HomeRepository>()));

  // ── Explore Cubit ──────────────────────────────────────────────────────────
  sl.registerFactory(
    () => ExploreCubit(
      getSuggestions: sl<GetSuggestionsUseCase>(),
      getDestinations: sl<GetDestinationsUseCase>(),
      getHotels: sl<GetHotelsUseCase>(),
      getItineraries: sl<GetItinerariesUseCase>(),
    ),
  );

  // ══════════════════════════════════════════════════════════════════════════
  // ── Itinerary Feature ──────────────────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════

  // ── Itinerary DataSource ───────────────────────────────────────────────────
  sl.registerLazySingleton<ItineraryDataSource>(
    () => MockItineraryDataSource(),
    // TODO: swap → RemoteItineraryDataSource(sl<DioClient>())
  );

  // ── Itinerary Repository ───────────────────────────────────────────────────
  sl.registerLazySingleton<ItineraryRepository>(
    () => ItineraryRepositoryImpl(sl<ItineraryDataSource>()),
  );

  // ── Itinerary UseCases ─────────────────────────────────────────────────────
  sl.registerLazySingleton(
      () => GetItinerariesUseCase(sl<ItineraryRepository>()));
  sl.registerLazySingleton(
      () => GetItinerarySummaryUseCase(sl<ItineraryRepository>()));
  sl.registerLazySingleton(
      () => DeleteItineraryUseCase(sl<ItineraryRepository>()));
  sl.registerLazySingleton(
      () => GetItineraryDetailUseCase(sl<ItineraryRepository>()));

  // ── Itinerary Cubit ────────────────────────────────────────────────────────
  sl.registerFactory(
    () => ItineraryCubit(
      getItineraries: sl<GetItinerariesUseCase>(),
      getSummary: sl<GetItinerarySummaryUseCase>(),
      deleteItinerary: sl<DeleteItineraryUseCase>(),
      getItineraryDetail: sl<GetItineraryDetailUseCase>(),
    ),
  );

  // ══════════════════════════════════════════════════════════════════════════
  // ── Profile Feature ────────────────────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════

  // ── Profile DataSource ───────────────────────────────────────────────────
  sl.registerLazySingleton<ProfileDataSource>(
    () => MockProfileDataSource(),
  );

  // ── Profile Repository ───────────────────────────────────────────────────
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(sl<ProfileDataSource>()),
  );

  // ── Profile UseCases ─────────────────────────────────────────────────────
  sl.registerLazySingleton(
      () => GetProfileUseCase(sl<ProfileRepository>()));
  sl.registerLazySingleton(
      () => GetRecentActivitiesUseCase(sl<ProfileRepository>()));

  // ── Profile Cubit ────────────────────────────────────────────────────────
  sl.registerFactory(
    () => ProfileCubit(
      getProfile: sl<GetProfileUseCase>(),
      getRecentActivities: sl<GetRecentActivitiesUseCase>(),
    ),
  );

  // ══════════════════════════════════════════════════════════════════════════
  // ── Review Feature ────────────────────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════

  sl.registerLazySingleton<ReviewDataSource>(
    () => MockReviewDataSource(),
  );

  sl.registerLazySingleton<ReviewRepository>(
    () => ReviewRepositoryImpl(sl<ReviewDataSource>()),
  );

  sl.registerLazySingleton(
      () => GetItineraryForReviewUseCase(sl<ReviewRepository>()));

  sl.registerFactory(
    () => ReviewCubit(
      getItineraryForReview: sl<GetItineraryForReviewUseCase>(),
    ),
  );

  // ══════════════════════════════════════════════════════════════════════════
  // ── Place Feature ──────────────────────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════

  sl.registerLazySingleton<PlaceDataSource>(
    () => MockPlaceDataSource(),
  );

  sl.registerLazySingleton<PlaceRepository>(
    () => PlaceRepositoryImpl(sl<PlaceDataSource>()),
  );

  sl.registerLazySingleton(
    () => GetPlaceDetailUseCase(sl<PlaceRepository>()),
  );

  sl.registerFactory(
    () => PlaceDetailCubit(
      getPlaceDetailUseCase: sl<GetPlaceDetailUseCase>(),
    ),
  );
  // ── Trip Planner Cubit ─────────────────────────────────────────────────────
  sl.registerFactory(() => TripPlannerCubit());
}
