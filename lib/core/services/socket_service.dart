import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../services/secure_storage_service.dart';
import '../network/api_endpoints.dart';

/// Model for Dosen location updates received via Socket
class DosenLocationUpdate {
  final String dosenId;
  final double latitude;
  final double longitude;
  final String positionName;
  final String lastUpdated;

  DosenLocationUpdate({
    required this.dosenId,
    required this.latitude,
    required this.longitude,
    required this.positionName,
    required this.lastUpdated,
  });

  factory DosenLocationUpdate.fromJson(Map<String, dynamic> json) {
    return DosenLocationUpdate(
      dosenId: json['dosen_id'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      positionName: json['position_name'] ?? '',
      lastUpdated: json['last_updated'] ?? '',
    );
  }
}

/// Model for Dosen online status updates
class DosenStatusUpdate {
  final String dosenId;
  final bool isOnline;

  DosenStatusUpdate({
    required this.dosenId,
    required this.isOnline,
  });

  factory DosenStatusUpdate.fromJson(Map<String, dynamic> json) {
    return DosenStatusUpdate(
      dosenId: json['dosen_id'] ?? '',
      isOnline: json['is_online'] ?? false,
    );
  }
}

/// Socket.IO service for real-time communication
class SocketService {
  final SecureStorageService _secureStorage;
  final SharedPreferences _sharedPreferences;

  io.Socket? _socket;
  bool _isConnected = false;
  bool _isLiveTrackingActive = false;

  // Keys for SharedPreferences
  static const String _liveTrackingKey = 'is_live_tracking_active';

  // Stream controllers for different events
  final _dosenMovedController =
      StreamController<DosenLocationUpdate>.broadcast();
  final _dosenStatusController =
      StreamController<DosenStatusUpdate>.broadcast();
  final _connectionStatusController = StreamController<bool>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  final _locationAckController = StreamController<String>.broadcast();

  // Public streams
  Stream<DosenLocationUpdate> get onDosenMoved => _dosenMovedController.stream;
  Stream<DosenStatusUpdate> get onDosenStatus => _dosenStatusController.stream;
  Stream<bool> get onConnectionStatus => _connectionStatusController.stream;
  Stream<String> get onError => _errorController.stream;
  Stream<String> get onLocationAck => _locationAckController.stream;

  bool get isConnected => _socket?.connected ?? false;
  bool get isLiveTrackingActive => _isLiveTrackingActive;

  SocketService(this._secureStorage, this._sharedPreferences) {
    // Load persisted live tracking state
    _isLiveTrackingActive =
        _sharedPreferences.getBool(_liveTrackingKey) ?? false;
  }

  /// Get the base URL for socket connection
  String get _baseUrl {
    return dotenv.env['API_URL_PRIMARY']?.trim() ??
        ApiEndpoints.baseUrl(ApiEndpoint.primary);
  }

  /// Initialize and connect to the socket server
  Future<void> connect() async {
    if (_isConnected && _socket != null && _socket!.connected) {
      // Already connected, emit current status
      _connectionStatusController.add(true);
      return;
    }

    // If socket exists but disconnected, clean it up first
    if (_socket != null && !_socket!.connected) {
      _socket?.dispose();
      _socket = null;
    }

    final token = await _secureStorage.getToken();
    if (token == null || token.isEmpty) {
      _errorController.add('No authentication token available');
      return;
    }

    _socket = io.io(
      _baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setPath(ApiEndpoints.socketPath)
          .setAuth({'token': token})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(1000)
          .build(),
    );

    _setupListeners();

    // Explicitly connect the socket
    _socket?.connect();
  }

  /// Setup socket event listeners
  void _setupListeners() {
    _socket?.onConnect((_) {
      _isConnected = true;
      _connectionStatusController.add(true);
    });

    _socket?.onDisconnect((_) {
      _isConnected = false;
      _connectionStatusController.add(false);
    });

    _socket?.onConnectError((error) {
      _isConnected = false;
      _connectionStatusController.add(false);
      _errorController.add('Connection error: $error');
    });

    _socket?.onError((error) {
      _errorController.add('Socket error: $error');
    });

    // Listen for dosen location updates
    _socket?.on('dosen_moved', (data) {
      if (data is Map<String, dynamic>) {
        final update = DosenLocationUpdate.fromJson(data);
        _dosenMovedController.add(update);
      }
    });

    // Listen for dosen status updates
    _socket?.on('dosen_status', (data) {
      if (data is Map<String, dynamic>) {
        final update = DosenStatusUpdate.fromJson(data);
        _dosenStatusController.add(update);
      }
    });
  }

  /// Join a dosen's room to receive their location updates (Mahasiswa only)
  void joinDosenRoom(String dosenId) {
    if (!_isConnected || _socket == null) {
      _errorController.add('Not connected to server');
      return;
    }

    _socket?.emit('join_dosen_room', {'dosen_id': dosenId});
  }

  /// Leave a dosen's room (Mahasiswa only)
  void leaveDosenRoom(String dosenId) {
    if (!_isConnected || _socket == null) {
      return;
    }

    _socket?.emit('leave_dosen_room', {'dosen_id': dosenId});
  }

  /// Update location (Dosen only) - for live tracking
  void updateLocation(double latitude, double longitude) {
    if (!_isConnected || _socket == null) {
      _errorController.add('Not connected to server');
      return;
    }

    _socket?.emit('update_location', {
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  /// Start live tracking mode
  void startLiveTracking() {
    _isLiveTrackingActive = true;
    _sharedPreferences.setBool(_liveTrackingKey, true);
  }

  /// Stop live tracking mode and disconnect
  void stopLiveTracking() {
    _isLiveTrackingActive = false;
    _sharedPreferences.setBool(_liveTrackingKey, false);
    disconnect();
  }

  /// Send a single location update - creates temporary connection
  /// This is for the "Send Location Once" feature
  Future<Map<String, dynamic>?> sendSingleLocationUpdate(
      double latitude, double longitude) async {
    // If live tracking is active, don't use temp socket
    if (_isLiveTrackingActive && _isConnected && _socket != null) {
      _socket?.emit('update_location', {
        'latitude': latitude,
        'longitude': longitude,
      });
      return {'success': true, 'position_name': null};
    }

    final token = await _secureStorage.getToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    final completer = Completer<Map<String, dynamic>?>();

    final tempSocket = io.io(
      _baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setPath(ApiEndpoints.socketPath)
          .setAuth({'token': token})
          .disableAutoConnect()
          .disableReconnection()
          .build(),
    );

    String? positionName;

    // Listen for acknowledgment with position_name
    tempSocket.on('location_accepted', (data) {
      if (data is Map<String, dynamic>) {
        positionName = data['position_name']?.toString();
      }
    });

    tempSocket.onConnect((_) {
      tempSocket.emit('update_location', {
        'latitude': latitude,
        'longitude': longitude,
      });

      // Give server time to process and respond, then disconnect
      Future.delayed(const Duration(milliseconds: 800), () {
        tempSocket.disconnect();
        tempSocket.dispose();
        if (!completer.isCompleted) {
          completer.complete({
            'success': true,
            'position_name': positionName,
          });
        }
      });
    });

    tempSocket.onConnectError((error) {
      tempSocket.dispose();
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    });

    tempSocket.connect();

    // Timeout after 10 seconds
    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        tempSocket.disconnect();
        tempSocket.dispose();
        return null;
      },
    );
  }

  /// Disconnect from the socket server
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _connectionStatusController.add(false);
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _dosenMovedController.close();
    _dosenStatusController.close();
    _connectionStatusController.close();
    _errorController.close();
    _locationAckController.close();
  }
}
