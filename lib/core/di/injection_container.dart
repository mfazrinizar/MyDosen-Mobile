import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/lecturer_location/data/datasources/lecturer_location_remote_data_source.dart';
import '../../features/lecturer_location/data/repositories/lecturer_location_repository_impl.dart';
import '../../features/lecturer_location/domain/repositories/lecturer_location_repository.dart';
import '../../features/lecturer_location/domain/usecases/get_lecturer_location.dart';
import '../../features/lecturer_location/presentation/bloc/lecturer_location_bloc.dart';
import '../../features/lecturer_location/presentation/bloc/map_cubit.dart';
import '../network/api_endpoints.dart';
import '../network/auth_interceptor.dart';
import '../theme/theme_bloc.dart';
import '../theme/theme_local_data_source.dart';
import '../theme/theme_repository.dart';

// Auth imports
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login.dart';
import '../../features/auth/domain/usecases/get_profile.dart';
import '../../features/auth/domain/usecases/logout.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

// Mahasiswa imports
import '../../features/mahasiswa/data/datasources/tracking_remote_data_source.dart';
import '../../features/mahasiswa/data/repositories/tracking_repository_impl.dart';
import '../../features/mahasiswa/domain/repositories/tracking_repository.dart';
import '../../features/mahasiswa/domain/usecases/tracking_usecases.dart';
import '../../features/mahasiswa/presentation/bloc/mahasiswa_bloc.dart';

// Dosen imports
import '../../features/dosen/data/datasources/dosen_remote_data_source.dart';
import '../../features/dosen/data/repositories/dosen_repository_impl.dart';
import '../../features/dosen/domain/repositories/dosen_repository.dart';
import '../../features/dosen/domain/usecases/dosen_usecases.dart';
import '../../features/dosen/presentation/bloc/dosen_bloc.dart';

// Admin imports
import '../../features/admin/data/datasources/admin_remote_data_source.dart';
import '../../features/admin/data/repositories/admin_repository_impl.dart';
import '../../features/admin/domain/repositories/admin_repository.dart';
import '../../features/admin/domain/usecases/admin_usecases.dart';
import '../../features/admin/presentation/bloc/admin_bloc.dart';

// Services
import '../services/secure_storage_service.dart';
import '../services/socket_service.dart';
import '../services/location_service.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //===========================================
  // Core Services
  //===========================================

  // SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  // Secure Storage Service
  sl.registerLazySingleton<SecureStorageService>(() => SecureStorageService());

  // Socket Service
  sl.registerLazySingleton<SocketService>(
    () => SocketService(sl<SecureStorageService>(), sl<SharedPreferences>()),
  );

  // Location Service
  sl.registerLazySingleton<LocationService>(() => LocationService());

  //===========================================
  // API Clients
  //===========================================

  // Primary Dio (legacy)
  final primaryDio = DioFactory.create(ApiEndpoint.primary);
  sl.registerLazySingleton<PrimaryApiClient>(
    () => PrimaryApiClient(dio: primaryDio),
  );

  // Authenticated API Client with auth interceptor
  sl.registerLazySingleton<AuthenticatedApiClient>(() {
    final dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl(ApiEndpoint.primary),
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));
    dio.interceptors.add(AuthInterceptor(sl<SecureStorageService>()));
    return AuthenticatedApiClient(dio);
  });

  //===========================================
  // Theme
  //===========================================

  sl.registerLazySingleton<ThemeLocalDataSource>(
    () => ThemeLocalDataSourceImpl(sl<SharedPreferences>()),
  );
  sl.registerLazySingleton<ThemeRepository>(
    () => ThemeRepositoryImpl(sl<ThemeLocalDataSource>()),
  );
  sl.registerLazySingleton<ThemeBloc>(() => ThemeBloc(sl<ThemeRepository>()));

  //===========================================
  // Auth Feature
  //===========================================

  // Data source
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(apiClient: sl<AuthenticatedApiClient>()),
  );

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl<AuthRemoteDataSource>(),
      secureStorage: sl<SecureStorageService>(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => Login(sl<AuthRepository>()));
  sl.registerLazySingleton(() => GetProfile(sl<AuthRepository>()));
  sl.registerLazySingleton(() => Logout(sl<AuthRepository>()));

  // Bloc
  sl.registerFactory(() => AuthBloc(
        loginUseCase: sl<Login>(),
        getProfileUseCase: sl<GetProfile>(),
        logoutUseCase: sl<Logout>(),
        authRepository: sl<AuthRepository>(),
      ));

  //===========================================
  // Mahasiswa Feature
  //===========================================

  // Data source
  sl.registerLazySingleton<TrackingRemoteDataSource>(
    () => TrackingRemoteDataSourceImpl(apiClient: sl<AuthenticatedApiClient>()),
  );

  // Repository
  sl.registerLazySingleton<TrackingRepository>(
    () => TrackingRepositoryImpl(
        remoteDataSource: sl<TrackingRemoteDataSource>()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetAllDosen(sl<TrackingRepository>()));
  sl.registerLazySingleton(
      () => RequestTrackingAccess(sl<TrackingRepository>()));
  sl.registerLazySingleton(() => GetMyRequests(sl<TrackingRepository>()));
  sl.registerLazySingleton(() => GetAllowedDosen(sl<TrackingRepository>()));
  sl.registerLazySingleton(() => GetDosenHistory(sl<TrackingRepository>()));

  // Bloc
  sl.registerFactory(() => MahasiswaBloc(
        getAllDosen: sl<GetAllDosen>(),
        requestTrackingAccess: sl<RequestTrackingAccess>(),
        getMyRequests: sl<GetMyRequests>(),
        getAllowedDosen: sl<GetAllowedDosen>(),
        getDosenHistory: sl<GetDosenHistory>(),
      ));

  //===========================================
  // Dosen Feature
  //===========================================

  // Data source
  sl.registerLazySingleton<DosenRemoteDataSource>(
    () => DosenRemoteDataSourceImpl(apiClient: sl<AuthenticatedApiClient>()),
  );

  // Repository
  sl.registerLazySingleton<DosenRepository>(
    () => DosenRepositoryImpl(remoteDataSource: sl<DosenRemoteDataSource>()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetPendingRequests(sl<DosenRepository>()));
  sl.registerLazySingleton(() => HandleTrackingRequest(sl<DosenRepository>()));
  sl.registerLazySingleton(() => GetOwnHistory(sl<DosenRepository>()));
  sl.registerLazySingleton(() => GetApprovedStudents(sl<DosenRepository>()));
  sl.registerLazySingleton(() => GetTrackingStudents(sl<DosenRepository>()));

  // Bloc
  sl.registerFactory(() => DosenBloc(
        getPendingRequests: sl<GetPendingRequests>(),
        handleTrackingRequest: sl<HandleTrackingRequest>(),
        getOwnHistory: sl<GetOwnHistory>(),
        getTrackingStudents: sl<GetTrackingStudents>(),
        socketService: sl<SocketService>(),
        locationService: sl<LocationService>(),
        sharedPreferences: sl<SharedPreferences>(),
        secureStorageService: sl<SecureStorageService>(),
      ));

  //===========================================
  // Admin Feature
  //===========================================

  // Data source
  sl.registerLazySingleton<AdminRemoteDataSource>(
    () => AdminRemoteDataSourceImpl(apiClient: sl<AuthenticatedApiClient>()),
  );

  // Repository
  sl.registerLazySingleton<AdminRepository>(
    () => AdminRepositoryImpl(remoteDataSource: sl<AdminRemoteDataSource>()),
  );

  // Use cases
  sl.registerLazySingleton(() => CreateUser(sl<AdminRepository>()));
  sl.registerLazySingleton(() => GetAllUsers(sl<AdminRepository>()));
  sl.registerLazySingleton(() => DeleteUser(sl<AdminRepository>()));
  sl.registerLazySingleton(() => AssignPermission(sl<AdminRepository>()));
  sl.registerLazySingleton(() => GetAllPermissions(sl<AdminRepository>()));

  // Bloc
  sl.registerFactory(() => AdminBloc(
        createUser: sl<CreateUser>(),
        getAllUsers: sl<GetAllUsers>(),
        deleteUser: sl<DeleteUser>(),
        assignPermission: sl<AssignPermission>(),
        getAllPermissions: sl<GetAllPermissions>(),
      ));

  //===========================================
  // Legacy Lecturer Location Feature
  //===========================================

  sl.registerFactory(
    () => LecturerLocationBloc(getLecturerLocation: sl()),
  );

  sl.registerFactory<MapCubit>(() => MapCubit());

  sl.registerLazySingleton(() => GetLecturerLocation(sl()));

  sl.registerLazySingleton<LecturerLocationRepository>(
    () => LecturerLocationRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton<LecturerLocationRemoteDataSource>(
    () =>
        LecturerLocationRemoteDataSourceImpl(apiClient: sl<PrimaryApiClient>()),
  );
}
