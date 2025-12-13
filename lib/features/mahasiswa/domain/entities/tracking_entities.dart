import 'package:equatable/equatable.dart';

/// Entity representing a Dosen's location information
class DosenLocation extends Equatable {
  final String userId;
  final String name;
  final String nidn;
  final double? latitude;
  final double? longitude;
  final String? positionName;
  final bool isOnline;
  final DateTime? lastUpdated;

  const DosenLocation({
    required this.userId,
    required this.name,
    required this.nidn,
    this.latitude,
    this.longitude,
    this.positionName,
    this.isOnline = false,
    this.lastUpdated,
  });

  bool get hasLocation => latitude != null && longitude != null;

  @override
  List<Object?> get props => [
        userId,
        name,
        nidn,
        latitude,
        longitude,
        positionName,
        isOnline,
        lastUpdated,
      ];
}

/// Entity for tracking permission
class TrackingPermission extends Equatable {
  final String id;
  final String studentId;
  final String lecturerId;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime? createdAt;

  // Additional fields for display
  final String? lecturerName;
  final String? lecturerNidn;
  final String? studentName;
  final String? studentNim;

  const TrackingPermission({
    required this.id,
    required this.studentId,
    required this.lecturerId,
    required this.status,
    this.createdAt,
    this.lecturerName,
    this.lecturerNidn,
    this.studentName,
    this.studentNim,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  @override
  List<Object?> get props => [
        id,
        studentId,
        lecturerId,
        status,
        createdAt,
        lecturerName,
        lecturerNidn,
        studentName,
        studentNim,
      ];
}

/// Entity for Dosen info (without location, for listing)
class DosenInfo extends Equatable {
  final String userId;
  final String name;
  final String nidn;
  final String?
      requestStatus; // null if no request, or 'pending'/'approved'/'rejected'

  const DosenInfo({
    required this.userId,
    required this.name,
    required this.nidn,
    this.requestStatus,
  });

  bool get hasRequest => requestStatus != null;
  bool get canRequest => requestStatus == null || requestStatus == 'rejected';

  @override
  List<Object?> get props => [userId, name, nidn, requestStatus];
}

/// Entity for location history
class LocationHistory extends Equatable {
  final String dosenId;
  final String dosenName;
  final List<DayHistory> history;

  const LocationHistory({
    required this.dosenId,
    required this.dosenName,
    required this.history,
  });

  @override
  List<Object?> get props => [dosenId, dosenName, history];
}

class DayHistory extends Equatable {
  final int dayOfWeek;
  final String dayName;
  final List<LocationLog> logs;

  const DayHistory({
    required this.dayOfWeek,
    required this.dayName,
    required this.logs,
  });

  @override
  List<Object?> get props => [dayOfWeek, dayName, logs];
}

class LocationLog extends Equatable {
  final String locationName;
  final double latitude;
  final double longitude;
  final DateTime? loggedAt;

  const LocationLog({
    required this.locationName,
    required this.latitude,
    required this.longitude,
    this.loggedAt,
  });

  @override
  List<Object?> get props => [locationName, latitude, longitude, loggedAt];
}
