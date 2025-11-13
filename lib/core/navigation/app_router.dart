import 'package:flutter/material.dart';
import '../../features/lecturer_location/presentation/pages/home_page.dart';
import '../../features/lecturer_location/presentation/pages/about_page.dart';

abstract class AppRoutes {
  static const String home = '/';
  static const String about = '/about';
}

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const HomePage());
      case AppRoutes.about:
        return MaterialPageRoute(builder: (_) => const AboutPage());
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
