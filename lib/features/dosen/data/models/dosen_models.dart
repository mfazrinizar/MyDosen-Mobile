import '../../../../core/utils/date_time_utils.dart';
import '../../domain/entities/dosen_entities.dart';

/// Model for tracking request from Mahasiswa
class TrackingRequestModel extends TrackingRequest {
  const TrackingRequestModel({
    required super.id,
    required super.studentId,
    required super.studentName,
    required super.studentEmail,
    required super.nim,
    required super.status,
    required super.createdAt,
  });

  factory TrackingRequestModel.fromJson(Map<String, dynamic> json) {
    return TrackingRequestModel(
      id: json['id'] ?? '',
      studentId: json['student_id'] ?? '',
      studentName: json['student_name'] ?? '',
      studentEmail: json['student_email'] ?? '',
      nim: json['nim'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt:
          DateTimeUtils.parseBackendDate(json['created_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'student_name': studentName,
      'student_email': studentEmail,
      'nim': nim,
      'status': status,
      'created_at': DateTimeUtils.formatForBackend(createdAt),
    };
  }
}

/// Model for location history
class DosenLocationHistoryModel extends DosenLocationHistory {
  const DosenLocationHistoryModel({
    required super.dayOfWeek,
    required super.dayName,
    required super.logs,
  });

  factory DosenLocationHistoryModel.fromJson(Map<String, dynamic> json) {
    final logsJson = json['logs'] as List<dynamic>? ?? [];
    return DosenLocationHistoryModel(
      dayOfWeek: json['day_of_week'] ?? 0,
      dayName: json['day_name'] ?? '',
      logs: logsJson.map((l) => LocationLogModel.fromJson(l)).toList(),
    );
  }
}

/// Model for location log
class LocationLogModel extends LocationLog {
  const LocationLogModel({
    required super.locationName,
    required super.latitude,
    required super.longitude,
    required super.loggedAt,
  });

  factory LocationLogModel.fromJson(Map<String, dynamic> json) {
    return LocationLogModel(
      locationName: json['location_name'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      loggedAt:
          DateTimeUtils.parseBackendDate(json['logged_at']) ?? DateTime.now(),
    );
  }
}

/// Model for approved student
class ApprovedStudentModel extends ApprovedStudent {
  const ApprovedStudentModel({
    required super.id,
    required super.studentId,
    required super.studentName,
    required super.studentEmail,
    required super.nim,
    required super.approvedAt,
  });

  factory ApprovedStudentModel.fromJson(Map<String, dynamic> json) {
    return ApprovedStudentModel(
      id: json['id'] ?? '',
      studentId: json['student_id'] ?? '',
      studentName: json['student_name'] ?? '',
      studentEmail: json['student_email'] ?? '',
      nim: json['nim'] ?? '',
      approvedAt:
          DateTimeUtils.parseBackendDate(json['created_at']) ?? DateTime.now(),
    );
  }
}

/// Model for tracking student (from GET /tracking/students)
class TrackingStudentModel extends TrackingStudent {
  const TrackingStudentModel({
    required super.id,
    required super.studentId,
    required super.name,
    required super.email,
    required super.nim,
    required super.status,
    required super.requestedAt,
    required super.isOnline,
  });

  factory TrackingStudentModel.fromJson(Map<String, dynamic> json) {
    return TrackingStudentModel(
      id: json['id'] ?? '',
      studentId: json['student_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      nim: json['nim'] ?? '',
      status: json['status'] ?? 'pending',
      requestedAt: DateTimeUtils.parseBackendDate(json['requested_at']) ??
          DateTime.now(),
      isOnline: json['is_online'] ?? false,
    );
  }
}
