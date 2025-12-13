import '../../domain/entities/user.dart';
import '../../../../core/utils/date_time_utils.dart';

/// User model with JSON serialization
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.role,
    super.nim,
    super.nidn,
    super.nip,
    super.createdAt,
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
      createdAt: DateTimeUtils.parseBackendDate(json['created_at']),
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
    };
  }
}

/// Login response model
class LoginResponseModel {
  final String message;
  final String token;
  final UserModel user;

  LoginResponseModel({
    required this.message,
    required this.token,
    required this.user,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      message: json['message'] ?? '',
      token: json['token'] ?? '',
      user: UserModel.fromJson(json['user'] ?? {}),
    );
  }
}
