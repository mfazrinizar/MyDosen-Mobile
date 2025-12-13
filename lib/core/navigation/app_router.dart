import 'package:flutter/material.dart';
import '../../features/lecturer_location/presentation/pages/home_page.dart';
import '../../features/lecturer_location/presentation/pages/about_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/mahasiswa/presentation/pages/mahasiswa_home_page.dart';
import '../../features/mahasiswa/presentation/pages/dosen_list_page.dart';
import '../../features/mahasiswa/presentation/pages/my_requests_page.dart';
import '../../features/mahasiswa/presentation/pages/tracking_osm_map_page.dart';
import '../../features/mahasiswa/presentation/pages/dosen_history_page.dart';
import '../../features/mahasiswa/presentation/pages/navigation_osm_map_page.dart';
import '../../features/dosen/presentation/pages/dosen_home_page.dart';
import '../../features/dosen/presentation/pages/dosen_requests_page.dart';
import '../../features/dosen/presentation/pages/dosen_own_history_page.dart';
import '../../features/dosen/presentation/pages/dosen_map_view_page.dart';
import '../../features/dosen/presentation/pages/dosen_students_page.dart';
import '../../features/admin/presentation/pages/admin_home_page.dart';
import '../../features/admin/presentation/pages/admin_users_page.dart';
import '../../features/admin/presentation/pages/admin_permissions_page.dart';
import '../../features/admin/presentation/pages/admin_create_user_page.dart';
import '../../features/admin/presentation/pages/admin_assign_permission_page.dart';

abstract class AppRoutes {
  static const String home = '/';
  static const String about = '/about';
  static const String login = '/login';
  static const String mahasiswaHome = '/mahasiswa';
  static const String dosenHome = '/dosen';
  static const String adminHome = '/admin';

  // Mahasiswa routes
  static const String dosenList = '/mahasiswa/dosen-list';
  static const String myRequests = '/mahasiswa/my-requests';
  static const String trackingMap = '/mahasiswa/tracking';
  static const String dosenHistory = '/mahasiswa/history';
  static const String navigationMap = '/mahasiswa/navigation';

  // Dosen routes
  static const String dosenRequests = '/dosen/requests';
  static const String dosenOwnHistory = '/dosen/history';
  static const String dosenMapView = '/dosen/map';
  static const String dosenStudents = '/dosen/students';

  // Admin routes
  static const String adminUsers = '/admin/users';
  static const String adminPermissions = '/admin/permissions';
  static const String adminCreateUser = '/admin/create-user';
  static const String adminAssignPermission = '/admin/assign-permission';
}

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const HomePage());
      case AppRoutes.about:
        return MaterialPageRoute(builder: (_) => const AboutPage());
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginPage());

      // Mahasiswa routes
      case AppRoutes.mahasiswaHome:
        return MaterialPageRoute(builder: (_) => const MahasiswaHomePage());
      case AppRoutes.dosenList:
        return MaterialPageRoute(builder: (_) => const DosenListPage());
      case AppRoutes.myRequests:
        return MaterialPageRoute(builder: (_) => const MyRequestsPage());
      case AppRoutes.trackingMap:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => TrackingOsmMapPage(
            dosenId: args?['dosenId'] ?? '',
            dosenName: args?['dosenName'] ?? '',
            initialLatitude: args?['latitude'],
            initialLongitude: args?['longitude'],
            initialPositionName: args?['positionName'],
            initialIsOnline: args?['isOnline'],
          ),
        );
      case AppRoutes.dosenHistory:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => DosenHistoryPage(
            dosenId: args?['dosenId'] ?? '',
            dosenName: args?['dosenName'] ?? '',
          ),
        );
      case AppRoutes.navigationMap:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => NavigationOsmMapPage(
            dosenId: args?['dosenId'] ?? '',
            dosenName: args?['dosenName'] ?? '',
            destinationLatitude:
                args?['dosenLatitude'] ?? args?['latitude'] ?? 0.0,
            destinationLongitude:
                args?['dosenLongitude'] ?? args?['longitude'] ?? 0.0,
            destinationName: args?['positionName'] ?? '',
            isOnline: args?['isOnline'],
          ),
        );

      // Dosen routes
      case AppRoutes.dosenHome:
        return MaterialPageRoute(builder: (_) => const DosenHomePage());
      case AppRoutes.dosenRequests:
        return MaterialPageRoute(builder: (_) => const DosenRequestsPage());
      case AppRoutes.dosenOwnHistory:
        return MaterialPageRoute(builder: (_) => const DosenOwnHistoryPage());
      case AppRoutes.dosenMapView:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => DosenMapViewPage(
            latitude: args?['latitude'] ?? 0.0,
            longitude: args?['longitude'] ?? 0.0,
          ),
        );
      case AppRoutes.dosenStudents:
        return MaterialPageRoute(builder: (_) => const DosenStudentsPage());

      // Admin routes
      case AppRoutes.adminHome:
        return MaterialPageRoute(builder: (_) => const AdminHomePage());
      case AppRoutes.adminUsers:
        return MaterialPageRoute(builder: (_) => const AdminUsersPage());
      case AppRoutes.adminPermissions:
        return MaterialPageRoute(builder: (_) => const AdminPermissionsPage());
      case AppRoutes.adminCreateUser:
        return MaterialPageRoute(builder: (_) => const AdminCreateUserPage());
      case AppRoutes.adminAssignPermission:
        return MaterialPageRoute(
            builder: (_) => const AdminAssignPermissionPage());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Not found')),
            body: Center(child: Text('Route ${settings.name} not found')),
          ),
        );
    }
  }
}
