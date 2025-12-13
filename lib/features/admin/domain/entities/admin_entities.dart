import 'package:equatable/equatable.dart';

/// Entity for a User in the system
class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? nim; // For mahasiswa
  final String? nidn; // For dosen
  final String? nip; // For admin
  final DateTime createdAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.nim,
    this.nidn,
    this.nip,
    required this.createdAt,
  });

  String get roleIdentifier {
    switch (role.toLowerCase()) {
      case 'mahasiswa':
        return nim ?? '-';
      case 'dosen':
        return nidn ?? '-';
      case 'admin':
        return nip ?? '-';
      default:
        return '-';
    }
  }

  String get roleLabel {
    switch (role.toLowerCase()) {
      case 'mahasiswa':
        return 'Mahasiswa';
      case 'dosen':
        return 'Dosen';
      case 'admin':
        return 'Admin';
      default:
        return role;
    }
  }

  @override
  List<Object?> get props => [id, name, email, role, nim, nidn, nip, createdAt];
}

/// Entity for tracking permission (admin view)
class AdminTrackingPermission extends Equatable {
  final String id;
  final String studentId;
  final String studentName;
  final String? studentNim;
  final String lecturerId;
  final String lecturerName;
  final String? lecturerNidn;
  final String status;
  final DateTime createdAt;

  const AdminTrackingPermission({
    required this.id,
    required this.studentId,
    required this.studentName,
    this.studentNim,
    required this.lecturerId,
    required this.lecturerName,
    this.lecturerNidn,
    required this.status,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        studentId,
        studentName,
        studentNim,
        lecturerId,
        lecturerName,
        lecturerNidn,
        status,
        createdAt,
      ];
}

/// Entity for creating a new user
class CreateUserParams extends Equatable {
  final String name;
  final String email;
  final String password;
  final String role;
  final String? nim;
  final String? nidn;
  final String? nip;

  const CreateUserParams({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.nim,
    this.nidn,
    this.nip,
  });

  Map<String, dynamic> toJson() {
    final json = {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    };
    if (nim != null) json['nim'] = nim!;
    if (nidn != null) json['nidn'] = nidn!;
    if (nip != null) json['nip'] = nip!;
    return json;
  }

  @override
  List<Object?> get props => [name, email, password, role, nim, nidn, nip];
}

/// Entity for assigning permission
class AssignPermissionParams extends Equatable {
  final String studentId;
  final String lecturerId;

  const AssignPermissionParams({
    required this.studentId,
    required this.lecturerId,
  });

  @override
  List<Object?> get props => [studentId, lecturerId];
}
