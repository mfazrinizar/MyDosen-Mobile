import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/utils/date_time_utils.dart';

class NavigationMapPage extends StatefulWidget {
  final String dosenId;
  final String dosenName;
  final double destinationLatitude;
  final double destinationLongitude;
  final String destinationName;

  const NavigationMapPage({
    super.key,
    required this.dosenId,
    required this.dosenName,
    required this.destinationLatitude,
    required this.destinationLongitude,
    required this.destinationName,
  });

  @override
  State<NavigationMapPage> createState() => _NavigationMapPageState();
}

class _NavigationMapPageState extends State<NavigationMapPage> {
  late SocketService _socketService;
  late LocationService _locationService;
  late MapController _mapController;

  StreamSubscription? _dosenMovedSubscription;
  StreamSubscription? _dosenStatusSubscription;
  StreamSubscription? _locationSubscription;
  StreamSubscription? _connectionStatusSubscription;

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

  @override
  void initState() {
    super.initState();
    _socketService = di.sl<SocketService>();
    _locationService = di.sl<LocationService>();
    _mapController = MapController();

    // Set initial destination
    _dosenLatitude = widget.destinationLatitude;
    _dosenLongitude = widget.destinationLongitude;
    _dosenPositionName = widget.destinationName;
    _isConnected = _socketService.isConnected;

    _initializeServices();
  }

  Future<void> _initializeServices() async {
    // Connect to socket for real-time dosen updates
    await _socketService.connect();
    _socketService.joinDosenRoom(widget.dosenId);

    _connectionStatusSubscription = _socketService.onConnectionStatus.listen((
      isConnected,
    ) {
      if (mounted) {
        setState(() => _isConnected = isConnected);
      }
    });

    // Listen for dosen location updates
    _dosenMovedSubscription = _socketService.onDosenMoved.listen((update) {
      if (mounted && update.dosenId == widget.dosenId) {
        setState(() {
          _dosenLatitude = update.latitude;
          _dosenLongitude = update.longitude;
          _dosenPositionName = update.positionName;
          _dosenLastUpdated = DateTimeUtils.parseBackendDate(
            update.lastUpdated,
          );
          _updateDistance();
        });
      }
    });

    // Listen for dosen status updates
    _dosenStatusSubscription = _socketService.onDosenStatus.listen((update) {
      if (mounted && update.dosenId == widget.dosenId) {
        setState(() => _dosenIsOnline = update.isOnline);
      }
    });

    // Start tracking user location
    await _startUserLocationTracking();
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

      _locationSubscription = _locationService.onLocationUpdate.listen((
        position,
      ) {
        if (mounted) {
          setState(() {
            _userLatitude = position.latitude;
            _userLongitude = position.longitude;
            _updateDistance();
          });

          // Auto-center on user if following
          if (_isFollowingUser && _isMapReady) {
            _mapController.move(
              LatLng(position.latitude, position.longitude),
              _mapController.camera.zoom,
            );
          }
        }
      });
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

  void _centerOnUser() {
    if (_userLatitude != null && _userLongitude != null && _isMapReady) {
      _mapController.move(LatLng(_userLatitude!, _userLongitude!), 16.0);
      setState(() => _isFollowingUser = true);
    }
  }

  void _centerOnDestination() {
    if (_isMapReady) {
      _mapController.move(LatLng(_dosenLatitude, _dosenLongitude), 16.0);
      setState(() => _isFollowingUser = false);
    }
  }

  void _fitBothMarkers() {
    if (_userLatitude == null || _userLongitude == null || !_isMapReady) return;

    final bounds = LatLngBounds(
      LatLng(
        math.min(_userLatitude!, _dosenLatitude),
        math.min(_userLongitude!, _dosenLongitude),
      ),
      LatLng(
        math.max(_userLatitude!, _dosenLatitude),
        math.max(_userLongitude!, _dosenLongitude),
      ),
    );

    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
    );
    setState(() => _isFollowingUser = false);
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
    _dosenMovedSubscription?.cancel();
    _dosenStatusSubscription?.cancel();
    _locationSubscription?.cancel();
    _connectionStatusSubscription?.cancel();
    _locationService.stopTracking();
    _socketService.leaveDosenRoom(widget.dosenId);
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    color: _dosenIsOnline
                        ? Colors.green[300]
                        : Colors.grey[400],
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
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userLatitude != null && _userLongitude != null
                  ? LatLng(_userLatitude!, _userLongitude!)
                  : LatLng(_dosenLatitude, _dosenLongitude),
              initialZoom: 15.0,
              minZoom: 3.0,
              maxZoom: 18.0,
              onMapReady: () {
                setState(() => _isMapReady = true);
                // Fit both markers when map is ready
                Future.delayed(
                  const Duration(milliseconds: 500),
                  _fitBothMarkers,
                );
              },
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  setState(() => _isFollowingUser = false);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.unsri.mydosen',
              ),
              // Draw line between user and destination
              if (_userLatitude != null && _userLongitude != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [
                        LatLng(_userLatitude!, _userLongitude!),
                        LatLng(_dosenLatitude, _dosenLongitude),
                      ],
                      color: AppTheme.primaryOrange.withValues(alpha: 0.7),
                      strokeWidth: 4,
                      borderColor: AppTheme.primaryOrange.withValues(
                        alpha: 0.3,
                      ),
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  // User marker (blue)
                  if (_userLatitude != null && _userLongitude != null)
                    Marker(
                      point: LatLng(_userLatitude!, _userLongitude!),
                      width: 50,
                      height: 50,
                      child: _buildUserMarker(),
                    ),
                  // Destination marker (orange)
                  Marker(
                    point: LatLng(_dosenLatitude, _dosenLongitude),
                    width: 60,
                    height: 60,
                    child: _buildDestinationMarker(),
                  ),
                ],
              ),
            ],
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
          _buildControlButtons(),
        ],
      ),
    );
  }

  Widget _buildUserMarker() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8),
        ],
      ),
      child: const Icon(Icons.navigation, color: Colors.white, size: 24),
    );
  }

  Widget _buildDestinationMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: _dosenIsOnline ? Colors.green : AppTheme.primaryOrange,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            Icons.person,
            color: _dosenIsOnline ? Colors.green : AppTheme.primaryOrange,
            size: 24,
          ),
        ),
        Container(
          width: 3,
          height: 10,
          decoration: BoxDecoration(
            color: _dosenIsOnline ? Colors.green : AppTheme.primaryOrange,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                            'GPS Aktif',
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
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
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

  Widget _buildControlButtons() {
    return Positioned(
      right: 16,
      bottom: 180,
      child: Column(
        children: [
          FloatingActionButton.small(
            heroTag: 'fit',
            onPressed: _fitBothMarkers,
            backgroundColor: Colors.white,
            child: const Icon(Icons.fit_screen, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'destination',
            onPressed: _centerOnDestination,
            backgroundColor: AppTheme.primaryOrange,
            child: const Icon(Icons.person_pin_circle, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'user',
            onPressed: _centerOnUser,
            backgroundColor: _isFollowingUser ? Colors.blue : Colors.white,
            child: Icon(
              Icons.my_location,
              color: _isFollowingUser ? Colors.white : Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}
