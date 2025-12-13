import 'package:equatable/equatable.dart';

/// Entity for tracking permission request from Mahasiswa
class TrackingRequest extends Equatable {
  final String id;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String nim;
  final String status;
  final DateTime createdAt;

  const TrackingRequest({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.nim,
    required this.status,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        studentId,
        studentName,
        studentEmail,
        nim,
        status,
        createdAt,
      ];
}

/// Entity for Dosen's location history entry
class DosenLocationHistory extends Equatable {
  final int dayOfWeek;
  final String dayName;
  final List<LocationLog> logs;

  const DosenLocationHistory({
    required this.dayOfWeek,
    required this.dayName,
    required this.logs,
  });

  @override
  List<Object?> get props => [dayOfWeek, dayName, logs];
}

/// Entity for a single location log
class LocationLog extends Equatable {
  final String locationName;
  final double latitude;
  final double longitude;
  final DateTime loggedAt;

  const LocationLog({
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.loggedAt,
  });

  @override
  List<Object?> get props => [locationName, latitude, longitude, loggedAt];
}

/// Entity for approved student tracker
class ApprovedStudent extends Equatable {
  final String id;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String nim;
  final DateTime approvedAt;

  const ApprovedStudent({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.nim,
    required this.approvedAt,
  });

  @override
  List<Object?> get props => [
        id,
        studentId,
        studentName,
        studentEmail,
        nim,
        approvedAt,
      ];
}

/// Entity for student who can track this dosen (from GET /tracking/students)
class TrackingStudent extends Equatable {
  final String id;
  final String studentId;
  final String name;
  final String email;
  final String nim;
  final String status;
  final DateTime requestedAt;
  final bool isOnline;

  const TrackingStudent({
    required this.id,
    required this.studentId,
    required this.name,
    required this.email,
    required this.nim,
    required this.status,
    required this.requestedAt,
    required this.isOnline,
  });

  @override
  List<Object?> get props => [
        id,
        studentId,
        name,
        email,
        nim,
        status,
        requestedAt,
        isOnline,
      ];
}
