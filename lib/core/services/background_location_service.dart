import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../network/api_endpoints.dart';

/// Notification channel ID for the foreground service
const String notificationChannelId = 'mydosen_location_tracking';
const String notificationChannelName = 'Location Tracking';
const int notificationId = 888;

/// Keys for SharedPreferences
const String kLiveTrackingActive = 'is_live_tracking_active';
const String kLastLatitude = 'last_latitude';
const String kLastLongitude = 'last_longitude';
const String kLastUpdateTime = 'last_update_time';
const String kAuthToken = 'background_auth_token';
const String kApiUrl = 'background_api_url';

/// Initialize the background service
/// Call this in main() before runApp()
Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  // Create notification channel for Android
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    notificationChannelId,
    notificationChannelName,
    description: 'Notifikasi untuk tracking lokasi dosen',
    importance: Importance.low,
    playSound: false,
    enableVibration: false,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Create the notification channel on Android
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Configure the background service
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart:
          false, // Don't auto-start on app launch - only when tracking is enabled
      autoStartOnBoot:
          true, // Auto-restart on device boot if tracking was active
      isForegroundMode: true,
      notificationChannelId: notificationChannelId,
      initialNotificationTitle: 'MyDosen Live Tracking',
      initialNotificationContent: 'Memulai tracking lokasi...',
      foregroundServiceNotificationId: notificationId,
      foregroundServiceTypes: [AndroidForegroundType.location],
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

/// iOS background handler
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

/// Main entry point for the background service
/// This runs in a separate isolate when the app is terminated
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Ensure Flutter bindings are initialized for background isolate
  DartPluginRegistrant.ensureInitialized();

  debugPrint('[BackgroundService] ===== SERVICE STARTED =====');

  // IMPORTANT: Create notification channel in the background isolate as well
  // This ensures the channel exists before the foreground service starts
  if (service is AndroidServiceInstance) {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      notificationChannelId,
      notificationChannelName,
      description: 'Notifikasi untuk tracking lokasi dosen',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Set as foreground service with notification - CRITICAL for background execution
    await service.setAsForegroundService();
    debugPrint('[BackgroundService] Foreground service set');
  }

  // Load environment variables in the background isolate
  try {
    await dotenv.load(fileName: ".env");
    debugPrint('[BackgroundService] Environment loaded');
  } catch (e) {
    debugPrint('[BackgroundService] Error loading env: $e');
  }

  // Get shared preferences instance
  final prefs = await SharedPreferences.getInstance();
  debugPrint('[BackgroundService] SharedPreferences loaded');

  // Socket.IO connection variables
  io.Socket? socket;
  bool isConnected = false;

  // Location stream subscription
  StreamSubscription<Position>? locationSubscription;

  // Timer for periodic updates (as backup)
  Timer? updateTimer;

  // Keepalive timer to ensure service doesn't get killed
  Timer? keepAliveTimer;

  // ============================================
  // Helper Functions (defined first to avoid reference errors)
  // ============================================

  /// Get the base URL for socket connection
  String getBaseUrl() {
    // First try to get from SharedPreferences (stored when tracking started)
    final storedUrl = prefs.getString(kApiUrl);
    if (storedUrl != null && storedUrl.isNotEmpty) {
      return storedUrl;
    }
    // Fallback to dotenv
    return dotenv.env['API_URL_PRIMARY']?.trim() ??
        ApiEndpoints.baseUrl(ApiEndpoint.primary);
  }

  /// Get auth token from SharedPreferences (stored when tracking started)
  String? getAuthToken() {
    return prefs.getString(kAuthToken);
  }

  /// Update the notification content
  void updateNotification(String content) {
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: 'MyDosen Live Tracking',
        content: content,
      );
    }
  }

  /// Send location update to server
  void sendLocationUpdate(double latitude, double longitude) {
    if (!isConnected || socket == null) {
      debugPrint('[BackgroundService] Cannot send location - not connected');
      return;
    }

    socket?.emit('update_location', {
      'latitude': latitude,
      'longitude': longitude,
    });

    // Save last location
    prefs.setDouble(kLastLatitude, latitude);
    prefs.setDouble(kLastLongitude, longitude);
    prefs.setString(kLastUpdateTime, DateTime.now().toIso8601String());

    debugPrint('[BackgroundService] Location sent: $latitude, $longitude');
  }

  /// Connect to socket server
  Future<void> connectSocket() async {
    debugPrint('[BackgroundService] connectSocket called');

    if (isConnected && socket != null && socket!.connected) {
      debugPrint('[BackgroundService] Socket already connected');
      return;
    }

    // Get token from SharedPreferences (stored when tracking started from the app)
    final token = getAuthToken();
    if (token == null || token.isEmpty) {
      debugPrint(
          '[BackgroundService] No auth token available in SharedPreferences');
      updateNotification('Error: Token tidak tersedia');
      return;
    }

    debugPrint('[BackgroundService] Token found, connecting to socket...');

    socket?.disconnect();
    socket?.dispose();

    final baseUrl = getBaseUrl();
    debugPrint('[BackgroundService] Connecting to: $baseUrl');

    socket = io.io(
      baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setPath(ApiEndpoints.socketPath)
          .setAuth({'token': token})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(
              double.maxFinite.toInt()) // Keep reconnecting forever
          .setReconnectionDelay(2000)
          .setReconnectionDelayMax(10000)
          .build(),
    );

    socket?.onConnect((_) {
      isConnected = true;
      debugPrint('[BackgroundService] Socket connected');
      updateNotification('Terhubung - Mengirim lokasi');
    });

    socket?.onDisconnect((_) {
      isConnected = false;
      debugPrint('[BackgroundService] Socket disconnected');
      updateNotification('Terputus - Mencoba menghubungkan ulang...');
    });

    socket?.onConnectError((error) {
      isConnected = false;
      debugPrint('[BackgroundService] Socket connection error: $error');
      updateNotification('Error koneksi - Mencoba ulang...');
    });

    socket?.onReconnect((_) {
      isConnected = true;
      debugPrint('[BackgroundService] Socket reconnected');
      updateNotification('Terhubung kembali - Mengirim lokasi');
    });

    socket?.connect();
  }

  /// Start location tracking
  Future<void> startLocationTracking() async {
    // Check permissions
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      debugPrint('[BackgroundService] Location permission denied');
      updateNotification('Izin lokasi ditolak');
      return;
    }

    // Check if location service is enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('[BackgroundService] Location service disabled');
      updateNotification('Layanan lokasi dinonaktifkan');
      return;
    }

    // Connect to socket first
    await connectSocket();

    // Cancel any existing subscription
    await locationSubscription?.cancel();

    // Start listening to location updates
    locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen(
      (Position position) {
        sendLocationUpdate(position.latitude, position.longitude);
        updateNotification(
          'Lokasi: ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}',
        );
      },
      onError: (error) {
        debugPrint('[BackgroundService] Location error: $error');
        updateNotification('Error lokasi: $error');
      },
    );

    // Start a backup timer to ensure periodic updates even if GPS doesn't fire
    updateTimer?.cancel();
    updateTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
        sendLocationUpdate(position.latitude, position.longitude);
      } catch (e) {
        debugPrint('[BackgroundService] Periodic location error: $e');
      }
    });

    updateNotification('Tracking aktif');
  }

  /// Stop location tracking
  Future<void> stopLocationTracking() async {
    await locationSubscription?.cancel();
    locationSubscription = null;

    updateTimer?.cancel();
    updateTimer = null;

    socket?.disconnect();
    socket?.dispose();
    socket = null;
    isConnected = false;

    await prefs.setBool(kLiveTrackingActive, false);

    debugPrint('[BackgroundService] Tracking stopped');
  }

  // Listen for service events from the app
  service.on('stop').listen((event) async {
    debugPrint('[BackgroundService] Received stop command');
    await stopLocationTracking();
    service.stopSelf();
  });

  service.on('startTracking').listen((event) async {
    debugPrint('[BackgroundService] Received startTracking command');
    await prefs.setBool(kLiveTrackingActive, true);
    await startLocationTracking();
  });

  service.on('stopTracking').listen((event) async {
    debugPrint('[BackgroundService] Received stopTracking command');
    await stopLocationTracking();
    // Stop the service completely when tracking is stopped
    keepAliveTimer?.cancel();
    service.stopSelf();
  });

  // Start keepalive timer to ensure service stays running
  keepAliveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
    debugPrint('[BackgroundService] Keepalive tick - service is running');
    // Reload tracking state to ensure it's still supposed to be active
    prefs.reload().then((_) {
      final stillActive = prefs.getBool(kLiveTrackingActive) ?? false;
      if (!stillActive) {
        debugPrint(
            '[BackgroundService] Tracking no longer active, stopping service');
        stopLocationTracking();
        keepAliveTimer?.cancel();
        service.stopSelf();
      }
    });
  });

  // Check if tracking should be active on service start
  final isTrackingActive = prefs.getBool(kLiveTrackingActive) ?? false;
  debugPrint('[BackgroundService] isTrackingActive: $isTrackingActive');

  if (isTrackingActive) {
    debugPrint('[BackgroundService] Resuming active tracking');
    await startLocationTracking();
  }
}

/// Helper class to manage background service from the app
class BackgroundLocationManager {
  static final BackgroundLocationManager _instance =
      BackgroundLocationManager._internal();
  factory BackgroundLocationManager() => _instance;
  BackgroundLocationManager._internal();

  final FlutterBackgroundService _service = FlutterBackgroundService();

  /// Check if the background service is running
  Future<bool> isServiceRunning() async {
    return await _service.isRunning();
  }

  /// Start live tracking with background service
  /// IMPORTANT: Call prepareForBackgroundTracking() before this!
  Future<bool> startLiveTracking() async {
    debugPrint('[BackgroundLocationManager] startLiveTracking called');

    // Save tracking state
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kLiveTrackingActive, true);

    // Verify that auth token is available for background service
    final token = prefs.getString(kAuthToken);
    if (token == null || token.isEmpty) {
      debugPrint(
          '[BackgroundLocationManager] WARNING: No auth token stored for background service!');
      debugPrint(
          '[BackgroundLocationManager] Call prepareForBackgroundTracking() first');
    }

    // Check if service is already running
    final isRunning = await _service.isRunning();
    debugPrint(
        '[BackgroundLocationManager] Service already running: $isRunning');

    if (isRunning) {
      // Service is running, send start tracking command
      debugPrint(
          '[BackgroundLocationManager] Sending startTracking command to existing service');
      _service.invoke('startTracking');
    } else {
      // Start the service
      debugPrint('[BackgroundLocationManager] Starting new service...');
      final started = await _service.startService();
      if (!started) {
        debugPrint('[BackgroundLocationManager] Failed to start service');
        return false;
      }
      debugPrint('[BackgroundLocationManager] Service started successfully');
      // The service will automatically start tracking since kLiveTrackingActive is true
    }

    debugPrint('[BackgroundLocationManager] Live tracking started');
    return true;
  }

  /// Prepare data needed for background tracking
  /// Call this BEFORE startLiveTracking() to ensure the background service has access to auth token
  Future<void> prepareForBackgroundTracking({
    required String authToken,
    String? apiUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Store auth token in SharedPreferences (accessible by background isolate)
    await prefs.setString(kAuthToken, authToken);
    debugPrint(
        '[BackgroundLocationManager] Auth token stored for background service');

    // Store API URL if provided
    if (apiUrl != null && apiUrl.isNotEmpty) {
      await prefs.setString(kApiUrl, apiUrl);
      debugPrint('[BackgroundLocationManager] API URL stored: $apiUrl');
    }
  }

  /// Stop live tracking
  Future<void> stopLiveTracking() async {
    debugPrint('[BackgroundLocationManager] stopLiveTracking called');

    // Save tracking state
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kLiveTrackingActive, false);

    // Check if service is running
    final isRunning = await _service.isRunning();

    if (isRunning) {
      // Send stop tracking command (this will also stop the service)
      _service.invoke('stopTracking');
    }

    debugPrint('[BackgroundLocationManager] Live tracking stopped');
  }

  /// Completely stop the background service
  Future<void> stopService() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kLiveTrackingActive, false);

    final isRunning = await _service.isRunning();
    if (isRunning) {
      _service.invoke('stop');
    }

    debugPrint('[BackgroundLocationManager] Service stopped');
  }

  /// Clear stored credentials (call when user logs out)
  Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kAuthToken);
    await prefs.remove(kApiUrl);
    await prefs.setBool(kLiveTrackingActive, false);
    debugPrint('[BackgroundLocationManager] Credentials cleared');
  }

  /// Get last known location from background service
  Future<Map<String, dynamic>?> getLastLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(kLastLatitude);
    final lng = prefs.getDouble(kLastLongitude);
    final time = prefs.getString(kLastUpdateTime);

    if (lat != null && lng != null) {
      return {
        'latitude': lat,
        'longitude': lng,
        'time': time,
      };
    }
    return null;
  }

  /// Check if live tracking is active (persisted state)
  /// Check if live tracking is active (persisted state)
  Future<bool> isLiveTrackingActive() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(kLiveTrackingActive) ?? false;
  }
}
