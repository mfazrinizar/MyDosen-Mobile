import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_theme.dart';

class DosenMapViewPage extends StatefulWidget {
  final double latitude;
  final double longitude;

  const DosenMapViewPage({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<DosenMapViewPage> createState() => _DosenMapViewPageState();
}

class _DosenMapViewPageState extends State<DosenMapViewPage> {
  late MapController _mapController;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  void _centerOnLocation() {
    if (_isMapReady) {
      _mapController.move(LatLng(widget.latitude, widget.longitude), 16.0);
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lokasi Saya')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(widget.latitude, widget.longitude),
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
                    point: LatLng(widget.latitude, widget.longitude),
                    width: 60,
                    height: 60,
                    child: _buildMarker(),
                  ),
                ],
              ),
            ],
          ),
          _buildInfoCard(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _centerOnLocation,
        backgroundColor: AppTheme.primaryOrange,
        child: const Icon(Icons.my_location),
      ),
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
            border: Border.all(color: AppTheme.primaryOrange, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.person,
            color: AppTheme.primaryOrange,
            size: 24,
          ),
        ),
        Container(
          width: 3,
          height: 10,
          decoration: BoxDecoration(
            color: AppTheme.primaryOrange,
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
              const Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: AppTheme.primaryOrange,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Lokasi Terakhir',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.pin_drop, color: Colors.grey[500], size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.latitude.toStringAsFixed(6)}, ${widget.longitude.toStringAsFixed(6)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
