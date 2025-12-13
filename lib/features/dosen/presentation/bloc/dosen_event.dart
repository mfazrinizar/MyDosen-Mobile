import 'package:equatable/equatable.dart';

abstract class DosenEvent extends Equatable {
  const DosenEvent();

  @override
  List<Object?> get props => [];
}

/// Load pending tracking requests
class LoadPendingRequestsEvent extends DosenEvent {}

/// Approve a tracking request
class ApproveRequestEvent extends DosenEvent {
  final String permissionId;
  final String studentName;

  const ApproveRequestEvent({
    required this.permissionId,
    required this.studentName,
  });

  @override
  List<Object?> get props => [permissionId, studentName];
}

/// Reject a tracking request
class RejectRequestEvent extends DosenEvent {
  final String permissionId;
  final String studentName;

  const RejectRequestEvent({
    required this.permissionId,
    required this.studentName,
  });

  @override
  List<Object?> get props => [permissionId, studentName];
}

/// Load own location history
class LoadOwnHistoryEvent extends DosenEvent {}

/// Load tracking students (students who can track this dosen)
class LoadTrackingStudentsEvent extends DosenEvent {}

/// Update location once
class SendLocationOnceEvent extends DosenEvent {
  final double latitude;
  final double longitude;

  const SendLocationOnceEvent({
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [latitude, longitude];
}

/// Start live tracking
class StartLiveTrackingEvent extends DosenEvent {}

/// Stop live tracking
class StopLiveTrackingEvent extends DosenEvent {}

/// Update location for live tracking
class UpdateLiveLocationEvent extends DosenEvent {
  final double latitude;
  final double longitude;

  const UpdateLiveLocationEvent({
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [latitude, longitude];
}

/// Initialize live tracking state on app startup
class InitializeLiveTrackingEvent extends DosenEvent {}

/// Continue with foreground-only tracking when background permission is denied
class ContinueWithForegroundOnlyEvent extends DosenEvent {}

/// Open app settings to grant background location permission
class OpenBackgroundPermissionSettingsEvent extends DosenEvent {}
