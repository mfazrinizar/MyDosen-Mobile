import 'package:equatable/equatable.dart';
import '../../domain/entities/dosen_entities.dart';

abstract class DosenState extends Equatable {
  const DosenState();

  @override
  List<Object?> get props => [];
}

class DosenInitial extends DosenState {}

class DosenLoading extends DosenState {}

/// State for pending requests
class PendingRequestsLoaded extends DosenState {
  final List<TrackingRequest> requests;

  const PendingRequestsLoaded(this.requests);

  @override
  List<Object?> get props => [requests];
}

/// State after handling a request
class RequestHandled extends DosenState {
  final String message;
  final String action; // 'approved' or 'rejected'
  final String studentName;

  const RequestHandled({
    required this.message,
    required this.action,
    required this.studentName,
  });

  @override
  List<Object?> get props => [message, action, studentName];
}

/// State for own history
class OwnHistoryLoaded extends DosenState {
  final List<DosenLocationHistory> history;

  const OwnHistoryLoaded(this.history);

  @override
  List<Object?> get props => [history];
}

/// State for location update success
class LocationUpdateSuccess extends DosenState {
  final String message;
  final String? positionName;

  const LocationUpdateSuccess(this.message, {this.positionName});

  @override
  List<Object?> get props => [message, positionName];
}

/// State for live tracking status
class LiveTrackingStatus extends DosenState {
  final bool isTracking;
  final double? lastLatitude;
  final double? lastLongitude;
  final String? positionName;
  final DateTime? lastUpdated;

  const LiveTrackingStatus({
    required this.isTracking,
    this.lastLatitude,
    this.lastLongitude,
    this.positionName,
    this.lastUpdated,
  });

  LiveTrackingStatus copyWith({
    bool? isTracking,
    double? lastLatitude,
    double? lastLongitude,
    String? positionName,
    DateTime? lastUpdated,
  }) {
    return LiveTrackingStatus(
      isTracking: isTracking ?? this.isTracking,
      lastLatitude: lastLatitude ?? this.lastLatitude,
      lastLongitude: lastLongitude ?? this.lastLongitude,
      positionName: positionName ?? this.positionName,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props =>
      [isTracking, lastLatitude, lastLongitude, positionName, lastUpdated];
}

/// State when background location permission is denied but user can choose to continue with foreground-only tracking
class BackgroundPermissionDenied extends DosenState {
  const BackgroundPermissionDenied();

  @override
  List<Object?> get props => [];
}

/// State for tracking students loaded
class TrackingStudentsLoaded extends DosenState {
  final List<TrackingStudent> students;

  const TrackingStudentsLoaded(this.students);

  @override
  List<Object?> get props => [students];
}

/// Error state
class DosenError extends DosenState {
  final String message;

  const DosenError(this.message);

  @override
  List<Object?> get props => [message];
}
