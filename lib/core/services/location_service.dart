import 'dart:async';
import 'package:geolocator/geolocator.dart';

/// Service for handling GPS location operations
class LocationService {
  StreamSubscription<Position>? _positionSubscription;
  final _locationController = StreamController<Position>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  Position? _lastPosition;
  bool _isTracking = false;

  Stream<Position> get onLocationUpdate => _locationController.stream;
  Stream<String> get onError => _errorController.stream;
  Position? get lastPosition => _lastPosition;
  bool get isTracking => _isTracking;

  /// Check and request location permissions
  Future<bool> checkAndRequestPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _errorController.add('Location services are disabled');
      return false;
    }

    // Check permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _errorController.add('Location permissions are denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _errorController.add(
          'Location permissions are permanently denied. Please enable them in settings.');
      return false;
    }

    return true;
  }

  /// Request background location permission (required for Android 10+ background tracking)
  /// Returns true if background location permission is granted
  Future<bool> requestBackgroundLocationPermission() async {
    // First ensure we have basic location permission
    final hasBasicPermission = await checkAndRequestPermission();
    if (!hasBasicPermission) return false;

    // Check current permission status
    final permission = await Geolocator.checkPermission();

    // On Android 10+, we need to check if we have "Allow all the time" permission
    // LocationPermission.always means background location is granted
    if (permission == LocationPermission.whileInUse) {
      // Need to request background location - user will be prompted to select "Allow all the time"
      final bgPermission = await Geolocator.requestPermission();
      return bgPermission == LocationPermission.always;
    }

    return permission == LocationPermission.always;
  }

  /// Check if background location permission is granted
  Future<bool> hasBackgroundLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always;
  }

  /// Get current position once
  Future<Position?> getCurrentPosition() async {
    final hasPermission = await checkAndRequestPermission();
    if (!hasPermission) return null;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      _lastPosition = position;
      return position;
    } catch (e) {
      _errorController.add('Failed to get current position: $e');
      return null;
    }
  }

  /// Start continuous location tracking
  Future<bool> startTracking({
    int distanceFilter = 10,
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) async {
    if (_isTracking) return true;

    final hasPermission = await checkAndRequestPermission();
    if (!hasPermission) return false;

    _isTracking = true;

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    ).listen(
      (Position position) {
        _lastPosition = position;
        _locationController.add(position);
      },
      onError: (error) {
        _errorController.add('Location stream error: $error');
      },
    );

    return true;
  }

  /// Stop continuous location tracking
  void stopTracking() {
    _isTracking = false;
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  /// Calculate distance between two coordinates in meters
  double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// Calculate bearing from one point to another
  double calculateBearing(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.bearingBetween(startLat, startLng, endLat, endLng);
  }

  /// Open location settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Open app settings
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Dispose resources
  void dispose() {
    stopTracking();
    _locationController.close();
    _errorController.close();
  }
}
