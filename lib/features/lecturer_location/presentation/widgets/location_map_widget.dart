import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import '../../../../core/theme/app_theme.dart';

class LocationMapWidget extends StatefulWidget {
  final String location;

  const LocationMapWidget({
    super.key,
    required this.location,
  });

  @override
  State<LocationMapWidget> createState() => _LocationMapWidgetState();
}

class _LocationMapWidgetState extends State<LocationMapWidget>
    with SingleTickerProviderStateMixin {
  late MapController mapController;
  bool _isMapReady = false;

  static final GeoPoint _unsriIndralaya = GeoPoint(
    latitude: -3.220082,
    longitude: 104.651250,
  );
  static final GeoPoint _unsriBukit = GeoPoint(
    latitude: -2.984777,
    longitude: 104.732148,
  );
  static final GeoPoint _indonesia = GeoPoint(
    latitude: -2.5,
    longitude: 118.0,
  );

  @override
  void initState() {
    super.initState();

    mapController = MapController(
      initPosition: _targetLocation,
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      _setupMap();
    });
  }

  Future<void> _setupMap() async {
    try {
      await mapController.setZoom(zoomLevel: _zoomLevel);
      await mapController.moveTo(_targetLocation);
      await Future.delayed(const Duration(milliseconds: 300));

      await mapController.addMarker(
        _targetLocation,
        markerIcon: MarkerIcon(
          icon: Icon(
            Icons.location_on,
            color: _markerColor,
            size: 56,
          ),
        ),
      );

      if (widget.location != 'Di Luar') {
        await mapController.drawCircle(
          CircleOSM(
            key: 'location_circle',
            centerPoint: _targetLocation,
            radius: 250,
            color: _locationColor.withValues(alpha: 0.2),
            strokeWidth: 3,
          ),
        );
      }

      setState(() {
        _isMapReady = true;
      });
    } catch (e) {
      debugPrint('Error setting up map: $e');
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        _setupMap();
      }
    }
  }

  Future<void> _zoomIn() async {
    try {
      await mapController.zoomIn();
    } catch (e) {
      debugPrint('Error zooming in: $e');
    }
  }

  Future<void> _zoomOut() async {
    try {
      await mapController.zoomOut();
    } catch (e) {
      debugPrint('Error zooming out: $e');
    }
  }

  Future<void> _goToCurrentLocation() async {
    try {
      await mapController.moveTo(_targetLocation);
      await mapController.setZoom(zoomLevel: _zoomLevel);
    } catch (e) {
      debugPrint('Error going to location: $e');
    }
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(LocationMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) {
      _isMapReady = false;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _setupMap();
        }
      });
    }
  }

  GeoPoint get _targetLocation {
    if (widget.location.contains('Indralaya')) {
      return _unsriIndralaya;
    } else if (widget.location.contains('Palembang')) {
      return _unsriBukit;
    }
    return _indonesia;
  }

  double get _zoomLevel {
    if (widget.location.contains('Indralaya') ||
        widget.location.contains('Palembang')) {
      return 16.5;
    }
    return 5.0;
  }

  Color get _locationColor {
    if (widget.location.contains('Indralaya')) {
      return AppTheme.locationIndralaya;
    } else if (widget.location.contains('Palembang')) {
      return AppTheme.locationPalembang;
    }
    return AppTheme.locationOutside;
  }

  Color get _markerColor {
    if (widget.location.contains('Indralaya')) {
      return AppTheme.locationIndralaya;
    } else if (widget.location.contains('Palembang')) {
      return AppTheme.locationPalembang;
    }
    return AppTheme.primaryOrange;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        OSMFlutter(
          controller: mapController,
          osmOption: OSMOption(
            zoomOption: const ZoomOption(
              initZoom: 16.5,
              minZoomLevel: 3,
              maxZoomLevel: 19,
              stepZoom: 1.0,
            ),
            staticPoints: [],
            roadConfiguration: const RoadOption(
              roadColor: Colors.blue,
            ),
            showDefaultInfoWindow: true,
            enableRotationByGesture: true,
          ),
          onMapIsReady: (isReady) {
            if (isReady) {
              debugPrint('Map is ready!');
            }
          },
          mapIsLoading: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryOrange,
                    ),
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Memuat peta...',
                  style: TextStyle(
                    color: AppTheme.primaryOrange,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!_isMapReady)
          Container(
            color:
                (isDark ? Colors.black : Colors.white).withValues(alpha: 0.8),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryOrange,
                      ),
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Memuat peta...',
                    style: TextStyle(
                      color: AppTheme.primaryOrange,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        Positioned(
          right: 16,
          bottom: 16,
          child: Column(
            children: [
              _buildControlButton(
                icon: Icons.add_rounded,
                onPressed: _zoomIn,
                tooltip: 'Zoom In',
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              _buildControlButton(
                icon: Icons.remove_rounded,
                onPressed: _zoomOut,
                tooltip: 'Zoom Out',
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              _buildControlButton(
                icon: Icons.my_location_rounded,
                onPressed: _goToCurrentLocation,
                tooltip: 'Ke Lokasi',
                isDark: isDark,
                isPrimary: true,
              ),
            ],
          ),
        ),
        if (_isMapReady && widget.location != 'Di Luar')
          Positioned(
            left: 16,
            top: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _locationColor,
                    _locationColor.withValues(alpha: 0.85),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: _locationColor.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.location.contains('Indralaya')
                        ? Icons.school_rounded
                        : Icons.business_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.location,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    required bool isDark,
    bool isPrimary = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: isPrimary
                  ? const LinearGradient(
                      colors: [
                        AppTheme.primaryOrange,
                        AppTheme.secondaryOrange,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color:
                  isPrimary ? null : (isDark ? Colors.grey[850] : Colors.white),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isPrimary
                    ? AppTheme.primaryOrange.withValues(alpha: 0.3)
                    : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isPrimary
                      ? AppTheme.primaryOrange.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: isPrimary
                  ? Colors.white
                  : (isDark ? Colors.white : Colors.grey[800]),
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
