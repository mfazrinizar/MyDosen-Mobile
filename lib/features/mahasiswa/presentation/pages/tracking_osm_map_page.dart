import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/utils/date_time_utils.dart';
import '../../../../core/navigation/app_router.dart';

class TrackingOsmMapPage extends StatefulWidget {
  final String dosenId;
  final String dosenName;
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialPositionName;
  final bool? initialIsOnline;

  const TrackingOsmMapPage({
    super.key,
    required this.dosenId,
    required this.dosenName,
    this.initialLatitude,
    this.initialLongitude,
    this.initialPositionName,
    this.initialIsOnline,
  });

  @override
  State<TrackingOsmMapPage> createState() => _TrackingOsmMapPageState();
}

class _TrackingOsmMapPageState extends State<TrackingOsmMapPage>
    with RouteAware {
  late SocketService _socketService;
  MapController? _mapController;

  StreamSubscription? _dosenMovedSubscription;
  StreamSubscription? _dosenStatusSubscription;
  StreamSubscription? _connectionStatusSubscription;

  double? _currentLatitude;
  double? _currentLongitude;
  String? _currentPositionName;
  bool _isOnline = false;
  DateTime? _lastUpdated;
  bool _isConnected = false;
  bool _isMapReady = false;
  bool _isDisposing = false;

  // Track marker position for reliable removal
  GeoPoint? _lastMarkerPosition;

  // Helper to round coordinates to avoid floating point precision issues
  GeoPoint _roundedGeoPoint(double lat, double lng) {
    return GeoPoint(
      latitude: double.parse(lat.toStringAsFixed(6)),
      longitude: double.parse(lng.toStringAsFixed(6)),
    );
  }

  @override
  void initState() {
    super.initState();
    _socketService = di.sl<SocketService>();

    // Set initial values
    _currentLatitude = widget.initialLatitude;
    _currentLongitude = widget.initialLongitude;
    _currentPositionName = widget.initialPositionName;
    _isOnline = widget.initialIsOnline ?? false;
    // Don't initialize _isConnected from socket service - rely on stream updates
    _isConnected = false;

    // Initialize map controller with initial position or default
    _initializeMapController();

    _initializeSocket();
  }

  void _initializeMapController() {
    _mapController = MapController(
      initPosition: _currentLatitude != null && _currentLongitude != null
          ? GeoPoint(
              latitude: _currentLatitude!,
              longitude: _currentLongitude!,
            )
          : GeoPoint(latitude: -2.9761, longitude: 104.7754), // Default UNSRI
    );
  }

  /// Refreshes the marker by removing all possible duplicates and adding fresh one
  Future<void> _refreshMarker() async {
    if (_currentLatitude == null ||
        _currentLongitude == null ||
        _mapController == null ||
        _isDisposing ||
        !_isMapReady) {
      return;
    }

    try {
      // Try to remove tracked marker position
      if (_lastMarkerPosition != null) {
        try {
          await _mapController!.removeMarker(_lastMarkerPosition!);
        } catch (_) {}
        _lastMarkerPosition = null;
      }

      // Also try to remove at current position (in case of duplicates)
      final currentPos =
          _roundedGeoPoint(_currentLatitude!, _currentLongitude!);
      for (int i = 0; i < 5; i++) {
        try {
          await _mapController!.removeMarker(currentPos);
        } catch (_) {
          break;
        }
      }

      // Add fresh marker
      await _mapController!.addMarker(
        currentPos,
        markerIcon: MarkerIcon(
          iconWidget: Icon(
            Icons.location_on,
            color: _isOnline ? Colors.green : AppTheme.primaryOrange,
            size: 108,
          ),
        ),
      );
      _lastMarkerPosition = currentPos;
    } catch (e) {
      debugPrint('Error refreshing marker: $e');
    }
  }

  void _initializeSocket() async {
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
        setState(() {
          _isConnected = isConnected;
        });
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

    _dosenMovedSubscription = _socketService.onDosenMoved.listen((update) {
      if (mounted && update.dosenId == widget.dosenId) {
        final oldLat = _currentLatitude;
        final oldLng = _currentLongitude;

        setState(() {
          _currentLatitude = update.latitude;
          _currentLongitude = update.longitude;
          _currentPositionName = update.positionName;
          _lastUpdated = DateTimeUtils.parseBackendDate(update.lastUpdated);
        });

        // Update marker on map
        if (_isMapReady) {
          _updateMarker(oldLat, oldLng);
        }
      }
    });

    _dosenStatusSubscription = _socketService.onDosenStatus.listen((update) {
      if (mounted && !_isDisposing && update.dosenId == widget.dosenId) {
        if (mounted) {
          setState(() {
            _isOnline = update.isOnline;
          });
        }
        // Update marker color when status changes
        if (_isMapReady &&
            _currentLatitude != null &&
            _currentLongitude != null) {
          _updateMarker(_currentLatitude, _currentLongitude);
        }
      }
    });
  }

  Future<void> _updateMarker(double? oldLat, double? oldLng) async {
    if (_currentLatitude == null ||
        _currentLongitude == null ||
        _mapController == null ||
        _isDisposing) {
      return;
    }

    try {
      // Remove marker using tracked position
      if (_lastMarkerPosition != null) {
        await _mapController!.removeMarker(_lastMarkerPosition!);
        _lastMarkerPosition = null;
      }

      // Create new marker position
      final newPosition =
          _roundedGeoPoint(_currentLatitude!, _currentLongitude!);

      // Add new marker
      await _mapController!.addMarker(
        newPosition,
        markerIcon: MarkerIcon(
          iconWidget: Icon(
            Icons.location_on,
            color: _isOnline ? Colors.green : AppTheme.primaryOrange,
            size: 108,
          ),
        ),
      );

      // Track the new marker position
      _lastMarkerPosition = newPosition;

      // Center map on new location
      await _mapController!.moveTo(
        GeoPoint(
          latitude: _currentLatitude!,
          longitude: _currentLongitude!,
        ),
        animate: true,
      );
    } catch (e) {
      debugPrint('Error updating marker: $e');
    }
  }

  void _centerOnLocation() async {
    if (_currentLatitude != null &&
        _currentLongitude != null &&
        _isMapReady &&
        _mapController != null) {
      await _mapController!.moveTo(
        GeoPoint(
          latitude: _currentLatitude!,
          longitude: _currentLongitude!,
        ),
        animate: true,
      );
      await _mapController!.setZoom(zoomLevel: 16);
    }
  }

  void _zoomIn() async {
    if (_mapController != null) {
      await _mapController!.zoomIn();
    }
  }

  void _zoomOut() async {
    if (_mapController != null) {
      await _mapController!.zoomOut();
    }
  }

  @override
  void dispose() {
    _isDisposing = true;
    _mapController?.dispose();
    _mapController = null;
    _dosenMovedSubscription?.cancel();
    _dosenStatusSubscription?.cancel();
    _connectionStatusSubscription?.cancel();
    _socketService.leaveDosenRoom(widget.dosenId);
    super.dispose();
  }

  /// Called when a route has been popped off and this route is now visible
  void _onReturnFromNavigation() {
    // Refresh marker when returning from navigation page
    if (_isMapReady && !_isDisposing) {
      _refreshMarker();
    }
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
              widget.dosenName,
              style: const TextStyle(fontSize: 16),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isOnline ? Colors.green : Colors.grey,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isOnline ? Colors.green[300] : Colors.grey[400],
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
      body: _currentLatitude == null || _currentLongitude == null
          ? _buildNoLocationState()
          : _buildMap(isDark),
    );
  }

  Widget _buildNoLocationState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Lokasi Tidak Tersedia',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _isOnline
                  ? 'Dosen sedang online tapi belum membagikan lokasi.'
                  : 'Dosen sedang offline. Lokasi akan ditampilkan saat dosen online.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            if (!_isConnected)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_off,
                      size: 18,
                      color: Colors.orange,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Tidak terhubung ke server',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap(bool isDark) {
    if (_mapController == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryOrange),
      );
    }

    return Stack(
      children: [
        OSMFlutter(
          controller: _mapController!,
          onMapIsReady: (isReady) async {
            if (isReady && !_isMapReady) {
              setState(() {
                _isMapReady = true;
              });

              // Reset marker tracking and add initial marker
              if (_currentLatitude != null && _currentLongitude != null) {
                _lastMarkerPosition = null;
                final newPosition =
                    _roundedGeoPoint(_currentLatitude!, _currentLongitude!);
                await _mapController!.addMarker(
                  newPosition,
                  markerIcon: MarkerIcon(
                    iconWidget: Icon(
                      Icons.location_on,
                      color: _isOnline ? Colors.green : AppTheme.primaryOrange,
                      size: 108,
                    ),
                  ),
                );
                _lastMarkerPosition = newPosition;
              }
            }
          },
          osmOption: OSMOption(
            zoomOption: const ZoomOption(
              initZoom: 16,
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
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.primaryOrange),
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
        Positioned(
          right: 16,
          bottom: 180,
          child: Column(
            children: [
              _buildControlButton(
                icon: Icons.add,
                onPressed: _zoomIn,
                tooltip: 'Zoom In',
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              _buildControlButton(
                icon: Icons.remove,
                onPressed: _zoomOut,
                tooltip: 'Zoom Out',
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              _buildControlButton(
                icon: Icons.navigation,
                onPressed: () async {
                  await Navigator.pushNamed(
                    context,
                    AppRoutes.navigationMap,
                    arguments: {
                      'dosenId': widget.dosenId,
                      'dosenName': widget.dosenName,
                      'dosenLatitude': _currentLatitude,
                      'dosenLongitude': _currentLongitude,
                      'positionName': _currentPositionName,
                      'isOnline': _isOnline,
                    },
                  );
                  // Refresh marker when returning from navigation
                  _onReturnFromNavigation();
                },
                tooltip: 'Navigasi',
                isDark: isDark,
                color: Colors.blue,
              ),
              const SizedBox(height: 8),
              _buildControlButton(
                icon: Icons.my_location,
                onPressed: _centerOnLocation,
                tooltip: 'Ke Lokasi',
                isDark: isDark,
                isPrimary: true,
              ),
            ],
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
                      colors: [
                        AppTheme.primaryOrange,
                        AppTheme.secondaryOrange
                      ],
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
                  const Icon(
                    Icons.location_on,
                    color: AppTheme.primaryOrange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _currentPositionName ?? 'Lokasi tidak diketahui',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.pin_drop,
                    color: Colors.grey[500],
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_currentLatitude!.toStringAsFixed(6)}, ${_currentLongitude!.toStringAsFixed(6)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              if (_lastUpdated != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: Colors.grey[500],
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Diperbarui ${DateTimeUtils.formatRelative(_lastUpdated!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
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
}
