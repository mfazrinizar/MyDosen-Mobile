import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/utils/date_time_utils.dart';
import '../../../../core/navigation/app_router.dart';

class TrackingMapPage extends StatefulWidget {
  final String dosenId;
  final String dosenName;
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialPositionName;
  final bool? initialIsOnline;

  const TrackingMapPage({
    super.key,
    required this.dosenId,
    required this.dosenName,
    this.initialLatitude,
    this.initialLongitude,
    this.initialPositionName,
    this.initialIsOnline,
  });

  @override
  State<TrackingMapPage> createState() => _TrackingMapPageState();
}

class _TrackingMapPageState extends State<TrackingMapPage> {
  late SocketService _socketService;
  late MapController _mapController;

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

  @override
  void initState() {
    super.initState();
    _socketService = di.sl<SocketService>();
    _mapController = MapController();

    // Set initial values
    _currentLatitude = widget.initialLatitude;
    _currentLongitude = widget.initialLongitude;
    _currentPositionName = widget.initialPositionName;
    _isOnline = widget.initialIsOnline ?? false;
    _isConnected = _socketService.isConnected; // Initialize with current state

    _initializeSocket();
  }

  void _initializeSocket() async {
    await _socketService.connect();

    // Join room for this dosen
    _socketService.joinDosenRoom(widget.dosenId);

    _connectionStatusSubscription = _socketService.onConnectionStatus.listen((
      isConnected,
    ) {
      if (mounted) {
        setState(() {
          _isConnected = isConnected;
        });
      }
    });

    _dosenMovedSubscription = _socketService.onDosenMoved.listen((update) {
      if (mounted && update.dosenId == widget.dosenId) {
        setState(() {
          _currentLatitude = update.latitude;
          _currentLongitude = update.longitude;
          _currentPositionName = update.positionName;
          _lastUpdated = DateTimeUtils.parseBackendDate(update.lastUpdated);
        });

        // Center map on new location
        if (_isMapReady &&
            _currentLatitude != null &&
            _currentLongitude != null) {
          _mapController.move(
            LatLng(_currentLatitude!, _currentLongitude!),
            _mapController.camera.zoom,
          );
        }
      }
    });

    _dosenStatusSubscription = _socketService.onDosenStatus.listen((update) {
      if (mounted && update.dosenId == widget.dosenId) {
        setState(() {
          _isOnline = update.isOnline;
        });
      }
    });
  }

  void _centerOnLocation() {
    if (_currentLatitude != null && _currentLongitude != null && _isMapReady) {
      _mapController.move(LatLng(_currentLatitude!, _currentLongitude!), 16.0);
    }
  }

  @override
  void dispose() {
    _dosenMovedSubscription?.cancel();
    _dosenStatusSubscription?.cancel();
    _connectionStatusSubscription?.cancel();
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
            Text(widget.dosenName, style: const TextStyle(fontSize: 16)),
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
          : _buildMap(),
      floatingActionButton:
          _currentLatitude != null && _currentLongitude != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'navigate',
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.navigationMap,
                      arguments: {
                        'dosenId': widget.dosenId,
                        'dosenName': widget.dosenName,
                        'dosenLatitude': _currentLatitude,
                        'dosenLongitude': _currentLongitude,
                        'positionName': _currentPositionName,
                      },
                    );
                  },
                  backgroundColor: Colors.blue,
                  tooltip: 'Navigasi ke lokasi dosen',
                  child: const Icon(Icons.navigation, color: Colors.white),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'center',
                  onPressed: _centerOnLocation,
                  backgroundColor: AppTheme.primaryOrange,
                  child: const Icon(Icons.my_location),
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildNoLocationState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 80, color: Colors.grey[400]),
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off, size: 18, color: Colors.orange),
                    const SizedBox(width: 8),
                    const Text(
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

  Widget _buildMap() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(_currentLatitude!, _currentLongitude!),
            initialZoom: 16.0,
            minZoom: 3.0,
            maxZoom: 18.0,
            onMapReady: () {
              setState(() {
                _isMapReady = true;
              });
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.unsri.mydosen',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(_currentLatitude!, _currentLongitude!),
                  width: 60,
                  height: 60,
                  child: _buildMarker(),
                ),
              ],
            ),
          ],
        ),
        _buildInfoCard(),
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
      ],
    );
  }

  Widget _buildMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: _isOnline ? Colors.green : Colors.grey,
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
            color: _isOnline ? Colors.green : Colors.grey,
            size: 24,
          ),
        ),
        Container(
          width: 3,
          height: 10,
          decoration: BoxDecoration(
            color: _isOnline ? Colors.green : Colors.grey,
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
                  Icon(Icons.pin_drop, color: Colors.grey[500], size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${_currentLatitude!.toStringAsFixed(6)}, ${_currentLongitude!.toStringAsFixed(6)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              if (_lastUpdated != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.grey[500], size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Diperbarui ${DateTimeUtils.formatRelative(_lastUpdated!)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
