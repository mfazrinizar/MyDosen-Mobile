import 'package:equatable/equatable.dart';

/// User entity representing a user in the system
class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final String role; // 'admin', 'dosen', 'mahasiswa'
  final String? nim; // For mahasiswa
  final String? nidn; // For dosen
  final String? nip; // For admin
  final DateTime? createdAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.nim,
    this.nidn,
    this.nip,
    this.createdAt,
  });

  bool get isAdmin => role == 'admin';
  bool get isDosen => role == 'dosen';
  bool get isMahasiswa => role == 'mahasiswa';

  @override
  List<Object?> get props => [id, name, email, role, nim, nidn, nip, createdAt];
}
