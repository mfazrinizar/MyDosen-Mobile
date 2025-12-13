import '../../../../core/utils/date_time_utils.dart';
import '../../domain/entities/admin_entities.dart';

/// Model for User
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.role,
    super.nim,
    super.nidn,
    super.nip,
    required super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      nim: json['nim'],
      nidn: json['nidn'],
      nip: json['nip'],
      createdAt:
          DateTimeUtils.parseBackendDate(json['created_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      if (nim != null) 'nim': nim,
      if (nidn != null) 'nidn': nidn,
      if (nip != null) 'nip': nip,
      'created_at': DateTimeUtils.formatForBackend(createdAt),
    };
  }
}

/// Model for AdminTrackingPermission
class AdminTrackingPermissionModel extends AdminTrackingPermission {
  const AdminTrackingPermissionModel({
    required super.id,
    required super.studentId,
    required super.studentName,
    super.studentNim,
    required super.lecturerId,
    required super.lecturerName,
    super.lecturerNidn,
    required super.status,
    required super.createdAt,
  });

  factory AdminTrackingPermissionModel.fromJson(Map<String, dynamic> json) {
    return AdminTrackingPermissionModel(
      id: json['id'] ?? '',
      studentId: json['student_id'] ?? '',
      studentName: json['student_name'] ?? json['student']?['name'] ?? '',
      studentNim: json['student_nim'] ?? json['student']?['nim'],
      lecturerId: json['lecturer_id'] ?? '',
      lecturerName: json['lecturer_name'] ?? json['lecturer']?['name'] ?? '',
      lecturerNidn: json['lecturer_nidn'] ?? json['lecturer']?['nidn'],
      status: json['status'] ?? 'pending',
      createdAt:
          DateTimeUtils.parseBackendDate(json['created_at']) ?? DateTime.now(),
    );
  }
}
