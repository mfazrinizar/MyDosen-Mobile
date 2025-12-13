import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/background_location_service.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/usecases/dosen_usecases.dart';
import 'dosen_event.dart';
import 'dosen_state.dart';

class DosenBloc extends Bloc<DosenEvent, DosenState> {
  final GetPendingRequests getPendingRequests;
  final HandleTrackingRequest handleTrackingRequest;
  final GetOwnHistory getOwnHistory;
  final GetTrackingStudents getTrackingStudents;
  final SocketService socketService;
  final LocationService locationService;
  final SharedPreferences sharedPreferences;
  final SecureStorageService secureStorageService;

  // Background location manager for persistent tracking
  final BackgroundLocationManager _backgroundManager =
      BackgroundLocationManager();

  StreamSubscription<Position>? _locationSubscription;
  bool _isLiveTracking = false;

  // Key for SharedPreferences
  static const String _liveTrackingKey = 'dosen_live_tracking_active';

  DosenBloc({
    required this.getPendingRequests,
    required this.handleTrackingRequest,
    required this.getOwnHistory,
    required this.getTrackingStudents,
    required this.socketService,
    required this.locationService,
    required this.sharedPreferences,
    required this.secureStorageService,
  }) : super(DosenInitial()) {
    // Load persisted live tracking state
    _isLiveTracking = sharedPreferences.getBool(_liveTrackingKey) ?? false;

    on<LoadPendingRequestsEvent>(_onLoadPendingRequests);
    on<ApproveRequestEvent>(_onApproveRequest);
    on<RejectRequestEvent>(_onRejectRequest);
    on<LoadOwnHistoryEvent>(_onLoadOwnHistory);
    on<LoadTrackingStudentsEvent>(_onLoadTrackingStudents);
    on<SendLocationOnceEvent>(_onSendLocationOnce);
    on<StartLiveTrackingEvent>(_onStartLiveTracking);
    on<StopLiveTrackingEvent>(_onStopLiveTracking);
    on<UpdateLiveLocationEvent>(_onUpdateLiveLocation);
    on<InitializeLiveTrackingEvent>(_onInitializeLiveTracking);
    on<ContinueWithForegroundOnlyEvent>(_onContinueWithForegroundOnly);
    on<OpenBackgroundPermissionSettingsEvent>(
        _onOpenBackgroundPermissionSettings);
  }

  Future<void> _onLoadPendingRequests(
    LoadPendingRequestsEvent event,
    Emitter<DosenState> emit,
  ) async {
    emit(DosenLoading());

    final result = await getPendingRequests(NoParams());

    result.fold(
      (failure) => emit(DosenError(failure.message)),
      (requests) => emit(PendingRequestsLoaded(requests)),
    );
  }

  Future<void> _onApproveRequest(
    ApproveRequestEvent event,
    Emitter<DosenState> emit,
  ) async {
    emit(DosenLoading());

    final result = await handleTrackingRequest(HandleRequestParams(
      permissionId: event.permissionId,
      action: 'approved',
    ));

    result.fold(
      (failure) => emit(DosenError(failure.message)),
      (response) => emit(RequestHandled(
        message: response['message'] ?? 'Permintaan disetujui',
        action: 'approved',
        studentName: event.studentName,
      )),
    );
  }

  Future<void> _onRejectRequest(
    RejectRequestEvent event,
    Emitter<DosenState> emit,
  ) async {
    emit(DosenLoading());

    final result = await handleTrackingRequest(HandleRequestParams(
      permissionId: event.permissionId,
      action: 'rejected',
    ));

    result.fold(
      (failure) => emit(DosenError(failure.message)),
      (response) => emit(RequestHandled(
        message: response['message'] ?? 'Permintaan ditolak',
        action: 'rejected',
        studentName: event.studentName,
      )),
    );
  }

  Future<void> _onLoadOwnHistory(
    LoadOwnHistoryEvent event,
    Emitter<DosenState> emit,
  ) async {
    emit(DosenLoading());

    final result = await getOwnHistory(NoParams());

    result.fold(
      (failure) => emit(DosenError(failure.message)),
      (history) => emit(OwnHistoryLoaded(history)),
    );
  }

  Future<void> _onLoadTrackingStudents(
    LoadTrackingStudentsEvent event,
    Emitter<DosenState> emit,
  ) async {
    emit(DosenLoading());

    final result = await getTrackingStudents(NoParams());

    result.fold(
      (failure) => emit(DosenError(failure.message)),
      (students) => emit(TrackingStudentsLoaded(students)),
    );
  }

  Future<void> _onSendLocationOnce(
    SendLocationOnceEvent event,
    Emitter<DosenState> emit,
  ) async {
    // Don't emit loading if live tracking is active
    if (!_isLiveTracking) {
      emit(DosenLoading());
    }

    try {
      final result = await socketService.sendSingleLocationUpdate(
        event.latitude,
        event.longitude,
      );

      if (result != null && result['success'] == true) {
        emit(LocationUpdateSuccess(
          'Lokasi berhasil dikirim',
          positionName: result['position_name'],
        ));
      } else {
        emit(const DosenError('Gagal mengirim lokasi'));
      }
    } catch (e) {
      emit(DosenError('Error: $e'));
    }
  }

  Future<void> _onStartLiveTracking(
    StartLiveTrackingEvent event,
    Emitter<DosenState> emit,
  ) async {
    if (_isLiveTracking) return;

    // Request location permission first (basic permission)
    final hasPermission = await locationService.checkAndRequestPermission();
    if (!hasPermission) {
      emit(const DosenError('Izin lokasi diperlukan untuk live tracking'));
      return;
    }

    // Request background location permission (required for tracking when app is closed)
    final hasBackgroundPermission =
        await locationService.requestBackgroundLocationPermission();
    if (!hasBackgroundPermission) {
      // Instead of showing error, emit state that allows user to choose
      emit(const BackgroundPermissionDenied());
      return;
    }

    // Get auth token and prepare background service BEFORE starting it
    final token = await secureStorageService.getToken();
    if (token == null || token.isEmpty) {
      emit(const DosenError('Token autentikasi tidak tersedia'));
      return;
    }

    // Get API URL
    final apiUrl = dotenv.env['API_URL_PRIMARY']?.trim() ??
        ApiEndpoints.baseUrl(ApiEndpoint.primary);

    // NOTE: Commented out prepareForBackgroundTracking since we're using FlutterSecureStorage directly

    // Prepare background service with credentials (stored in SharedPreferences for background isolate access)
    await _backgroundManager.prepareForBackgroundTracking(
      authToken: token,
      apiUrl: apiUrl,
    );

    // Start background service for persistent tracking
    final started = await _backgroundManager.startLiveTracking();
    if (!started) {
      emit(const DosenError('Gagal memulai background service'));
      return;
    }
    _isLiveTracking = true;
    await sharedPreferences.setBool(_liveTrackingKey, true);

    // Also start foreground location tracking for immediate UI updates
    await locationService.startTracking(
      distanceFilter: 10,
      accuracy: LocationAccuracy.high,
    );

    // Connect socket for immediate updates while app is in foreground
    await socketService.connect();
    socketService.startLiveTracking();

    // Listen to location updates for UI updates
    _locationSubscription = locationService.onLocationUpdate.listen((position) {
      add(UpdateLiveLocationEvent(
        latitude: position.latitude,
        longitude: position.longitude,
      ));
    });

    emit(const LiveTrackingStatus(isTracking: true));
  }

  Future<void> _onStopLiveTracking(
    StopLiveTrackingEvent event,
    Emitter<DosenState> emit,
  ) async {
    _isLiveTracking = false;
    await sharedPreferences.setBool(_liveTrackingKey, false);

    // Stop background service
    await _backgroundManager.stopLiveTracking();

    // Cancel foreground location subscription
    await _locationSubscription?.cancel();
    _locationSubscription = null;

    // Stop foreground location service
    locationService.stopTracking();

    // Stop socket live tracking (this will disconnect)
    socketService.stopLiveTracking();

    emit(const LiveTrackingStatus(isTracking: false));
  }

  void _onUpdateLiveLocation(
    UpdateLiveLocationEvent event,
    Emitter<DosenState> emit,
  ) {
    if (!_isLiveTracking) return;

    // Send to server via socket (foreground only - background service handles its own updates)
    socketService.updateLocation(event.latitude, event.longitude);

    emit(LiveTrackingStatus(
      isTracking: true,
      lastLatitude: event.latitude,
      lastLongitude: event.longitude,
      lastUpdated: DateTime.now(),
    ));
  }

  Future<void> _onInitializeLiveTracking(
    InitializeLiveTrackingEvent event,
    Emitter<DosenState> emit,
  ) async {
    // Check if background tracking is active
    final isBackgroundActive = await _backgroundManager.isLiveTrackingActive();

    // Sync local state with background service state
    if (isBackgroundActive != _isLiveTracking) {
      _isLiveTracking = isBackgroundActive;
      await sharedPreferences.setBool(_liveTrackingKey, isBackgroundActive);
    }

    // If live tracking was previously active, resume foreground components
    if (_isLiveTracking) {
      // Get last known location from background service
      final lastLocation = await _backgroundManager.getLastLocation();

      // Start foreground location tracking for UI updates
      final started = await locationService.startTracking(
        distanceFilter: 10,
        accuracy: LocationAccuracy.high,
      );

      if (started) {
        // Connect to socket for foreground updates
        await socketService.connect();
        socketService.startLiveTracking();

        // Listen to location updates for UI
        _locationSubscription =
            locationService.onLocationUpdate.listen((position) {
          add(UpdateLiveLocationEvent(
            latitude: position.latitude,
            longitude: position.longitude,
          ));
        });

        // Emit current status with last known location if available
        emit(LiveTrackingStatus(
          isTracking: true,
          lastLatitude: lastLocation?['latitude'],
          lastLongitude: lastLocation?['longitude'],
          lastUpdated: lastLocation?['time'] != null
              ? DateTime.tryParse(lastLocation!['time'])
              : null,
        ));
      } else {
        // If foreground tracking failed, still show as tracking
        // because background service is still running
        emit(LiveTrackingStatus(
          isTracking: true,
          lastLatitude: lastLocation?['latitude'],
          lastLongitude: lastLocation?['longitude'],
        ));
      }
    } else {
      // Emit the current status (not tracking)
      emit(const LiveTrackingStatus(isTracking: false));
    }
  }

  Future<void> _onContinueWithForegroundOnly(
    ContinueWithForegroundOnlyEvent event,
    Emitter<DosenState> emit,
  ) async {
    await _startForegroundOnlyTracking(emit);
  }

  Future<void> _onOpenBackgroundPermissionSettings(
    OpenBackgroundPermissionSettingsEvent event,
    Emitter<DosenState> emit,
  ) async {
    await locationService.openAppSettings();
  }

  /// Start foreground-only tracking (when background permission is denied)
  Future<void> _startForegroundOnlyTracking(Emitter<DosenState> emit) async {
    _isLiveTracking = true;
    await sharedPreferences.setBool(_liveTrackingKey, true);

    // Start only foreground location tracking
    await locationService.startTracking(
      distanceFilter: 10,
      accuracy: LocationAccuracy.high,
    );

    // Connect socket for updates while app is in foreground
    await socketService.connect();
    socketService.startLiveTracking();

    // Listen to location updates for UI updates
    _locationSubscription = locationService.onLocationUpdate.listen((position) {
      add(UpdateLiveLocationEvent(
        latitude: position.latitude,
        longitude: position.longitude,
      ));
    });

    emit(const LiveTrackingStatus(isTracking: true));
  }

  @override
  Future<void> close() {
    // Only cancel foreground location subscription
    // Don't stop background service - it should continue running
    _locationSubscription?.cancel();
    locationService.stopTracking();

    // Only disconnect foreground socket, not background tracking
    // Background service has its own socket connection
    if (_isLiveTracking) {
      // Just disconnect the foreground socket connection
      // but don't call stopLiveTracking() as that would stop background service too
      socketService.disconnect();
    }
    return super.close();
  }
}
