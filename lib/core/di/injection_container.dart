import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/lecturer_location/data/datasources/lecturer_location_remote_data_source.dart';
import '../../features/lecturer_location/data/repositories/lecturer_location_repository_impl.dart';
import '../../features/lecturer_location/domain/repositories/lecturer_location_repository.dart';
import '../../features/lecturer_location/domain/usecases/get_lecturer_location.dart';
import '../../features/lecturer_location/presentation/bloc/lecturer_location_bloc.dart';
import '../../features/lecturer_location/presentation/bloc/map_cubit.dart';
import '../network/api_endpoints.dart';
import '../theme/theme_bloc.dart';
import '../theme/theme_local_data_source.dart';
import '../theme/theme_repository.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Feature BLoC
  sl.registerFactory(
    () => LecturerLocationBloc(
      getLecturerLocation: sl(),
    ),
  );

  // Map presentation cubit
  sl.registerFactory<MapCubit>(() => MapCubit());

  // SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  // Theme local data source & repository
  sl.registerLazySingleton<ThemeLocalDataSource>(
    () => ThemeLocalDataSourceImpl(sl<SharedPreferences>()),
  );
  sl.registerLazySingleton<ThemeRepository>(
    () => ThemeRepositoryImpl(sl<ThemeLocalDataSource>()),
  );

  // ThemeBloc as a single instance app-wide
  sl.registerLazySingleton<ThemeBloc>(() => ThemeBloc(sl<ThemeRepository>()));

  // Use cases
  sl.registerLazySingleton(() => GetLecturerLocation(sl()));

  // Repository
  sl.registerLazySingleton<LecturerLocationRepository>(
    () => LecturerLocationRepositoryImpl(
      remoteDataSource: sl(),
    ),
  );

  final primaryDio = DioFactory.create(ApiEndpoint.primary);
  sl.registerLazySingleton<PrimaryApiClient>(
      () => PrimaryApiClient(dio: primaryDio));

  // Data sources (inject typed ApiClient)
  sl.registerLazySingleton<LecturerLocationRemoteDataSource>(
    () =>
        LecturerLocationRemoteDataSourceImpl(apiClient: sl<PrimaryApiClient>()),
  );
}
