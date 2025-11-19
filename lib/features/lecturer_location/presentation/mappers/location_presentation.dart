import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import '../../../../core/theme/app_theme.dart';

class LocationPresentation {
  final GeoPoint point;
  final double zoom;
  final Color color;
  final IconData icon;
  final bool drawCircle;

  const LocationPresentation({
    required this.point,
    required this.zoom,
    required this.color,
    required this.icon,
    required this.drawCircle,
  });

  static LocationPresentation fromLocationString(String location) {
    final locLower = location.toLowerCase();
    if (locLower.contains('indralaya')) {
      return LocationPresentation(
        point: GeoPoint(latitude: -3.220082, longitude: 104.651250),
        zoom: 16.5,
        color: AppTheme.locationIndralaya,
        icon: Icons.school_rounded,
        drawCircle: true,
      );
    } else if (locLower.contains('palembang')) {
      return LocationPresentation(
        point: GeoPoint(latitude: -2.984777, longitude: 104.732148),
        zoom: 16.5,
        color: AppTheme.locationPalembang,
        icon: Icons.business_rounded,
        drawCircle: true,
      );
    } else {
      return LocationPresentation(
        point: GeoPoint(latitude: -2.5, longitude: 118.0),
        zoom: 5.0,
        color: AppTheme.primaryOrange,
        icon: Icons.explore_rounded,
        drawCircle: false,
      );
    }
  }
}
