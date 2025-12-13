import '../../domain/entities/tracking_entities.dart';
import '../../../../core/utils/date_time_utils.dart';

/// Model for Dosen location with JSON serialization
class DosenLocationModel extends DosenLocation {
  const DosenLocationModel({
    required super.userId,
    required super.name,
    required super.nidn,
    super.latitude,
    super.longitude,
    super.positionName,
    super.isOnline,
    super.lastUpdated,
  });

  factory DosenLocationModel.fromJson(Map<String, dynamic> json) {
    return DosenLocationModel(
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      nidn: json['nidn'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      positionName: json['position_name'],
      isOnline: json['is_online'] ?? false,
      lastUpdated: DateTimeUtils.parseBackendDate(json['last_updated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'nidn': nidn,
      'latitude': latitude,
      'longitude': longitude,
      'position_name': positionName,
      'is_online': isOnline,
    };
  }
}

/// Model for tracking permission with JSON serialization
class TrackingPermissionModel extends TrackingPermission {
  const TrackingPermissionModel({
    required super.id,
    required super.studentId,
    required super.lecturerId,
    required super.status,
    super.createdAt,
    super.lecturerName,
    super.lecturerNidn,
    super.studentName,
    super.studentNim,
  });

  factory TrackingPermissionModel.fromJson(Map<String, dynamic> json) {
    return TrackingPermissionModel(
      id: json['id'] ?? '',
      studentId: json['student_id'] ?? '',
      lecturerId: json['lecturer_id'] ?? '',
      status: json['status'] ?? '',
      createdAt: DateTimeUtils.parseBackendDate(json['created_at']),
      lecturerName: json['lecturer_name'],
      lecturerNidn: json['lecturer_nidn'],
      studentName: json['student_name'],
      studentNim: json['nim'] ?? json['student_nim'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'lecturer_id': lecturerId,
      'status': status,
    };
  }
}

/// Model for Dosen info (listing) with JSON serialization
class DosenInfoModel extends DosenInfo {
  const DosenInfoModel({
    required super.userId,
    required super.name,
    required super.nidn,
    super.requestStatus,
  });

  factory DosenInfoModel.fromJson(Map<String, dynamic> json) {
    return DosenInfoModel(
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      nidn: json['nidn'] ?? '',
      requestStatus: json['request_status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'nidn': nidn,
      'request_status': requestStatus,
    };
  }
}

/// Model for location history with JSON serialization
class LocationHistoryModel extends LocationHistory {
  const LocationHistoryModel({
    required super.dosenId,
    required super.dosenName,
    required super.history,
  });

  factory LocationHistoryModel.fromJson(Map<String, dynamic> json) {
    final historyList = (json['history'] as List<dynamic>?)
            ?.map((e) => DayHistoryModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return LocationHistoryModel(
      dosenId: json['dosen_id'] ?? '',
      dosenName: json['dosen_name'] ?? '',
      history: historyList,
    );
  }
}

class DayHistoryModel extends DayHistory {
  const DayHistoryModel({
    required super.dayOfWeek,
    required super.dayName,
    required super.logs,
  });

  factory DayHistoryModel.fromJson(Map<String, dynamic> json) {
    final logsList = (json['logs'] as List<dynamic>?)
            ?.map((e) => LocationLogModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return DayHistoryModel(
      dayOfWeek: json['day_of_week'] ?? 0,
      dayName: json['day_name'] ?? '',
      logs: logsList,
    );
  }
}

class LocationLogModel extends LocationLog {
  const LocationLogModel({
    required super.locationName,
    required super.latitude,
    required super.longitude,
    super.loggedAt,
  });

  factory LocationLogModel.fromJson(Map<String, dynamic> json) {
    return LocationLogModel(
      locationName: json['location_name'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      loggedAt: DateTimeUtils.parseBackendDate(json['logged_at']),
    );
  }
}
