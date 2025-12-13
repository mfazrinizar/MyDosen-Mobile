import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/navigation/app_router.dart';
import 'features/lecturer_location/presentation/bloc/lecturer_location_event.dart';
import 'core/di/injection_container.dart' as di;
import 'core/theme/app_theme.dart';
import 'features/lecturer_location/presentation/bloc/lecturer_location_bloc.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/mahasiswa/presentation/bloc/mahasiswa_bloc.dart';
import 'features/dosen/presentation/bloc/dosen_bloc.dart';
import 'features/admin/presentation/bloc/admin_bloc.dart';
import 'core/theme/theme_bloc.dart';
import 'core/theme/theme_event.dart';
import 'core/theme/theme_state.dart';
import 'core/services/background_location_service.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Initialize local notifications first (creates notification channel)
  await _initializeNotifications();

  // Initialize background service (must be after notifications)
  await initializeBackgroundService();

  await di.init();
  await initializeDateFormatting('id_ID', null);

  runApp(const MyApp());
}

/// Initialize Flutter Local Notifications
Future<void> _initializeNotifications() async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Android initialization settings
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/launcher_icon');

  // iOS initialization settings
  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      // Handle notification tap
      debugPrint('Notification tapped: ${response.payload}');
    },
  );

  // Create the notification channel for background service BEFORE requesting permissions
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'mydosen_location_tracking',
    'Location Tracking',
    description: 'Notifikasi untuk tracking lokasi dosen',
    importance: Importance.low,
    playSound: false,
    enableVibration: false,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Request notification permissions on Android 13+
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LecturerLocationBloc>(
          create: (_) =>
              di.sl<LecturerLocationBloc>()..add(GetLecturerLocationEvent()),
        ),
        BlocProvider<ThemeBloc>(
          create: (_) => di.sl<ThemeBloc>()..add(LoadThemeEvent()),
        ),
        BlocProvider<AuthBloc>(
          create: (_) => di.sl<AuthBloc>()..add(CheckAuthStatusEvent()),
        ),
        BlocProvider<MahasiswaBloc>(
          create: (_) => di.sl<MahasiswaBloc>(),
        ),
        BlocProvider<DosenBloc>(
          create: (_) => di.sl<DosenBloc>(),
        ),
        BlocProvider<AdminBloc>(
          create: (_) => di.sl<AdminBloc>(),
        ),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, state) {
          final themeMode = (state is ThemeLoaded)
              ? (state.isDark ? ThemeMode.dark : ThemeMode.light)
              : ThemeMode.system;
          return MaterialApp(
            title: 'MyDosen',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: const _AuthWrapper(),
            onGenerateRoute: AppRouter.generateRoute,
          );
        },
      ),
    );
  }
}

/// Wrapper widget that handles authentication state routing
class _AuthWrapper extends StatelessWidget {
  const _AuthWrapper();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        // Handle navigation based on auth state changes
      },
      builder: (context, state) {
        if (state is AuthLoading || state is AuthInitial) {
          return const _SplashScreen();
        }

        if (state is Authenticated) {
          // Route based on user role
          final role = state.user.role.toLowerCase();
          switch (role) {
            case 'mahasiswa':
            case 'student':
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context)
                    .pushReplacementNamed(AppRoutes.mahasiswaHome);
              });
              return const _SplashScreen();
            case 'dosen':
            case 'lecturer':
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pushReplacementNamed(AppRoutes.dosenHome);
              });
              return const _SplashScreen();
            case 'admin':
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pushReplacementNamed(AppRoutes.adminHome);
              });
              return const _SplashScreen();
            default:
              // Unknown role, go to login
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pushReplacementNamed(AppRoutes.login);
              });
              return const _SplashScreen();
          }
        }

        // Unauthenticated or error - go to login
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.login);
        });
        return const _SplashScreen();
      },
    );
  }
}

/// Splash screen shown during auth check
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryOrange,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Image.asset(
                'assets/images/icon-full.png',
                width: 80,
                height: 80,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'MyDosen',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tracking Dosen Real-time',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
