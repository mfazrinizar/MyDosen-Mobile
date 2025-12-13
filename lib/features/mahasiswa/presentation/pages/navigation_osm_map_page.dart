import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/utils/date_time_utils.dart';

class NavigationOsmMapPage extends StatefulWidget {
  final String dosenId;
  final String dosenName;
  final double destinationLatitude;
  final double destinationLongitude;
  final String destinationName;
  final bool? isOnline;

  const NavigationOsmMapPage({
    super.key,
    required this.dosenId,
    required this.dosenName,
    required this.destinationLatitude,
    required this.destinationLongitude,
    required this.destinationName,
    this.isOnline,
  });

  @override
  State<NavigationOsmMapPage> createState() => _NavigationOsmMapPageState();
}

class _NavigationOsmMapPageState extends State<NavigationOsmMapPage> {
  late SocketService _socketService;
  late LocationService _locationService;
  MapController? _mapController;

  StreamSubscription? _dosenMovedSubscription;
  StreamSubscription? _dosenStatusSubscription;
  StreamSubscription? _locationSubscription;
  StreamSubscription? _connectionStatusSubscription;

  bool _isDisposing = false;

  // Dosen (destination) location
  double _dosenLatitude = 0;
  double _dosenLongitude = 0;
  String _dosenPositionName = '';
  bool _dosenIsOnline = false;
  DateTime? _dosenLastUpdated;

  // User (mahasiswa) location
  double? _userLatitude;
  double? _userLongitude;

  bool _isConnected = false;
  bool _isMapReady = false;
  bool _isTracking = false;
  bool _isFollowingUser = true;

  // Distance
  double _distanceToDestination = 0;

  // Track if markers have been added
  bool _userMarkerAdded = false;
  bool _dosenMarkerAdded = false;

  @override
  void initState() {
    super.initState();
    _socketService = di.sl<SocketService>();
    _locationService = di.sl<LocationService>();

    // Set initial destination
    _dosenLatitude = widget.destinationLatitude;
    _dosenLongitude = widget.destinationLongitude;
    _dosenPositionName = widget.destinationName;
    _dosenIsOnline = widget.isOnline ?? false;
    // Don't initialize _isConnected from socket service - rely on stream updates
    _isConnected = false;

    // Initialize map controller
    _initializeMapController();

    _initializeServices();
  }

  void _initializeMapController() {
    _mapController = MapController(
      initPosition: GeoPoint(
        latitude: _dosenLatitude,
        longitude: _dosenLongitude,
      ),
    );
  }

  Future<void> _initializeServices() async {
    // Connect to socket for real-time dosen updates
    await _socketService.connect();

    // Check connection status immediately and after a short delay
    if (mounted) {
      setState(() {
        _isConnected = _socketService.isConnected;
      });
    }

    // Check again after a short delay in case connection takes time
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && !_isConnected) {
        setState(() {
          _isConnected = _socketService.isConnected;
        });
      }
    });

    _connectionStatusSubscription =
        _socketService.onConnectionStatus.listen((isConnected) {
      if (mounted) {
        setState(() => _isConnected = isConnected);
      }
      // Join room when connection is established
      if (isConnected) {
        _socketService.joinDosenRoom(widget.dosenId);
      }
    });

    // Join room immediately if already connected
    if (_socketService.isConnected) {
      _socketService.joinDosenRoom(widget.dosenId);
    }

    // Listen for dosen location updates
    _dosenMovedSubscription = _socketService.onDosenMoved.listen((update) {
      if (mounted && update.dosenId == widget.dosenId) {
        _updateDosenLocation(
          update.latitude,
          update.longitude,
          update.positionName,
          update.lastUpdated,
        );
      }
    });

    // Listen for dosen status updates
    _dosenStatusSubscription = _socketService.onDosenStatus.listen((update) {
      if (mounted && update.dosenId == widget.dosenId) {
        setState(() => _dosenIsOnline = update.isOnline);
        _updateDosenMarker();
      }
    });

    // Start tracking user location
    await _startUserLocationTracking();
  }

  Future<void> _updateDosenLocation(
    double lat,
    double lng,
    String positionName,
    String lastUpdated,
  ) async {
    final oldLat = _dosenLatitude;
    final oldLng = _dosenLongitude;

    setState(() {
      _dosenLatitude = lat;
      _dosenLongitude = lng;
      _dosenPositionName = positionName;
      _dosenLastUpdated = DateTimeUtils.parseBackendDate(lastUpdated);
      _updateDistance();
    });

    if (_isMapReady && _mapController != null && !_isDisposing) {
      // Remove old marker
      if (_dosenMarkerAdded) {
        try {
          await _mapController!.removeMarker(
            GeoPoint(latitude: oldLat, longitude: oldLng),
          );
        } catch (_) {}
      }

      // Add new marker
      await _addDosenMarker();
      await _drawRouteLine();
    }
  }

  Future<void> _updateDosenMarker() async {
    if (!_isMapReady || _mapController == null || _isDisposing) return;

    // Remove and re-add marker with new color
    if (_dosenMarkerAdded) {
      try {
        await _mapController!.removeMarker(
          GeoPoint(latitude: _dosenLatitude, longitude: _dosenLongitude),
        );
      } catch (_) {}
    }
    await _addDosenMarker();
  }

  Future<void> _addDosenMarker() async {
    if (_mapController == null || _isDisposing) return;

    try {
      await _mapController!.addMarker(
        GeoPoint(latitude: _dosenLatitude, longitude: _dosenLongitude),
        markerIcon: MarkerIcon(
          iconWidget: Icon(
            Icons.location_on,
            color: _dosenIsOnline ? Colors.green : AppTheme.primaryOrange,
            size: 108,
          ),
        ),
      );
      _dosenMarkerAdded = true;
    } catch (e) {
      debugPrint('Error adding dosen marker: $e');
    }
  }

  Future<void> _addUserMarker() async {
    if (_userLatitude == null ||
        _userLongitude == null ||
        _mapController == null ||
        _isDisposing) {
      return;
    }

    try {
      await _mapController!.addMarker(
        GeoPoint(latitude: _userLatitude!, longitude: _userLongitude!),
        markerIcon: MarkerIcon(
          iconWidget: Icon(
            Icons.navigation_rounded,
            color: Colors.blue,
            size: 108,
          ),
        ),
      );
      _userMarkerAdded = true;
    } catch (e) {
      debugPrint('Error adding user marker: $e');
    }
  }

  Future<void> _startUserLocationTracking() async {
    final hasPermission = await _locationService.checkAndRequestPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Izin lokasi diperlukan untuk navigasi'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Get initial position
    final position = await _locationService.getCurrentPosition();
    if (position != null && mounted) {
      setState(() {
        _userLatitude = position.latitude;
        _userLongitude = position.longitude;
        _updateDistance();
      });
    }

    // Start continuous tracking
    final started = await _locationService.startTracking(
      distanceFilter: 5,
      accuracy: LocationAccuracy.high,
    );

    if (started) {
      setState(() => _isTracking = true);

      _locationSubscription =
          _locationService.onLocationUpdate.listen((position) async {
        if (mounted) {
          final oldLat = _userLatitude;
          final oldLng = _userLongitude;

          setState(() {
            _userLatitude = position.latitude;
            _userLongitude = position.longitude;
            _updateDistance();
          });

          // Update user marker
          if (_isMapReady && _mapController != null && !_isDisposing) {
            // Remove old marker
            if (_userMarkerAdded && oldLat != null && oldLng != null) {
              try {
                await _mapController!.removeMarker(
                  GeoPoint(latitude: oldLat, longitude: oldLng),
                );
              } catch (_) {}
            }

            await _addUserMarker();

            // Auto-center on user if following
            if (_isFollowingUser && _mapController != null) {
              await _mapController!.moveTo(
                GeoPoint(
                    latitude: position.latitude, longitude: position.longitude),
                animate: true,
              );
            }
          }
        }
      });
    }
  }

  Future<void> _drawRouteLine() async {
    if (_userLatitude == null ||
        _userLongitude == null ||
        !_isMapReady ||
        _mapController == null ||
        _isDisposing) {
      return;
    }

    // Temporarily disabled to prevent crashes
    try {
      // Clear existing roads
      await _mapController!.clearAllRoads();
    } catch (e) {
      if (!_isDisposing) debugPrint('Error clearing roads: $e');
    }

    try {
      // Draw a simple line between user and dosen
      await _mapController!.drawRoad(
        GeoPoint(latitude: _userLatitude!, longitude: _userLongitude!),
        GeoPoint(latitude: _dosenLatitude, longitude: _dosenLongitude),
        roadType: RoadType.car,
        roadOption: const RoadOption(
          roadWidth: 25,
          roadColor: AppTheme.primaryOrange,
          zoomInto: false,
        ),
      );
    } catch (e) {
      if (!_isDisposing) debugPrint('Error drawing route: $e');
    }
  }

  void _updateDistance() {
    if (_userLatitude != null && _userLongitude != null) {
      _distanceToDestination = _locationService.calculateDistance(
        _userLatitude!,
        _userLongitude!,
        _dosenLatitude,
        _dosenLongitude,
      );
    }
  }

  void _centerOnUser() async {
    if (_userLatitude != null &&
        _userLongitude != null &&
        _isMapReady &&
        _mapController != null) {
      await _mapController!.moveTo(
        GeoPoint(latitude: _userLatitude!, longitude: _userLongitude!),
        animate: true,
      );
      await _mapController!.setZoom(zoomLevel: 16);
      setState(() => _isFollowingUser = true);
    }
  }

  void _centerOnDestination() async {
    if (_isMapReady && _mapController != null) {
      await _mapController!.moveTo(
        GeoPoint(latitude: _dosenLatitude, longitude: _dosenLongitude),
        animate: true,
      );
      await _mapController!.setZoom(zoomLevel: 16);
      setState(() => _isFollowingUser = false);
    }
  }

  void _fitBothMarkers() async {
    if (_userLatitude == null ||
        _userLongitude == null ||
        !_isMapReady ||
        _mapController == null) {
      return;
    }

    try {
      final bounds = BoundingBox(
        north: math.max(_userLatitude!, _dosenLatitude),
        south: math.min(_userLatitude!, _dosenLatitude),
        east: math.max(_userLongitude!, _dosenLongitude),
        west: math.min(_userLongitude!, _dosenLongitude),
      );

      await _mapController!.zoomToBoundingBox(
        bounds,
        paddinInPixel: 100,
      );
      setState(() => _isFollowingUser = false);
    } catch (e) {
      debugPrint('Error fitting bounds: $e');
    }
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  @override
  void dispose() {
    _isDisposing = true;
    _locationSubscription?.cancel();
    _dosenMovedSubscription?.cancel();
    _dosenStatusSubscription?.cancel();
    _connectionStatusSubscription?.cancel();
    _locationService.stopTracking();
    // _socketService.leaveDosenRoom(widget.dosenId);
    _mapController?.dispose();
    _mapController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Navigasi ke ${widget.dosenName}',
              style: const TextStyle(fontSize: 16),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _dosenIsOnline ? Colors.green : Colors.grey,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _dosenIsOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        _dosenIsOnline ? Colors.green[300] : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (!_isConnected)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(Icons.cloud_off, color: Colors.orange),
            ),
        ],
      ),
      body: Stack(
        children: [
          if (_mapController == null)
            const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryOrange),
            )
          else
            OSMFlutter(
              controller: _mapController!,
              onMapIsReady: (isReady) async {
                if (isReady && !_isMapReady) {
                  setState(() => _isMapReady = true);

                  // Add markers
                  await _addDosenMarker();
                  if (_userLatitude != null && _userLongitude != null) {
                    await _addUserMarker();
                    await _drawRouteLine();
                    // Fit both markers
                    Future.delayed(
                      const Duration(milliseconds: 500),
                      _fitBothMarkers,
                    );
                  }
                }
              },
              osmOption: OSMOption(
                zoomOption: const ZoomOption(
                  initZoom: 15,
                  minZoomLevel: 3,
                  maxZoomLevel: 19,
                  stepZoom: 1.0,
                ),
                showDefaultInfoWindow: false,
                enableRotationByGesture: true,
              ),
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
                            AppTheme.primaryOrange),
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
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
          // Connection status banner
          if (!_isConnected)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_off, size: 16, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Tidak terhubung - Menunggu koneksi...',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          // Info card
          _buildInfoCard(),
          // Control buttons
          _buildControlButtons(isDark),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 80,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.directions,
                      color: AppTheme.primaryOrange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDistance(_distanceToDestination),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        Text(
                          'menuju ${widget.dosenName}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isTracking)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.gps_fixed, size: 14, color: Colors.green),
                          SizedBox(width: 4),
                          Text(
                            'GPS',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const Divider(height: 20),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: AppTheme.primaryOrange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _dosenPositionName.isNotEmpty
                          ? _dosenPositionName
                          : 'Lokasi tidak diketahui',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (_dosenLastUpdated != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 8),
                    Text(
                      'Diperbarui ${DateTimeUtils.formatRelative(_dosenLastUpdated!)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButtons(bool isDark) {
    return Positioned(
      right: 16,
      bottom: 180,
      child: Column(
        children: [
          _buildControlButton(
            icon: Icons.fit_screen,
            onPressed: _fitBothMarkers,
            tooltip: 'Tampilkan Semua',
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            icon: Icons.person_pin_circle,
            onPressed: _centerOnDestination,
            tooltip: 'Ke Dosen',
            isDark: isDark,
            color: AppTheme.primaryOrange,
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            icon: Icons.my_location,
            onPressed: _centerOnUser,
            tooltip: 'Lokasi Saya',
            isDark: isDark,
            isPrimary: _isFollowingUser,
            color: _isFollowingUser ? null : Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    required bool isDark,
    bool isPrimary = false,
    Color? color,
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
                      colors: [Colors.blue, Colors.blueAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isPrimary
                  ? null
                  : (color ?? (isDark ? Colors.grey[850] : Colors.white)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isPrimary
                    ? Colors.blue.withValues(alpha: 0.3)
                    : (color != null
                        ? color.withValues(alpha: 0.3)
                        : (isDark ? Colors.grey[700]! : Colors.grey[300]!)),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isPrimary
                      ? Colors.blue.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: isPrimary || color != null
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
