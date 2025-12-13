import 'package:flutter/foundation.dart' show kDebugMode;

import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/admin_entities.dart';
import '../models/admin_models.dart';

abstract class AdminRemoteDataSource {
  /// POST /admin/users - Create a new user
  Future<UserModel> createUser(CreateUserParams params);

  /// GET /admin/users - Get all users
  Future<List<UserModel>> getAllUsers();

  /// DELETE /admin/users/{id} - Delete a user
  Future<void> deleteUser(String userId);

  /// POST /admin/permissions - Assign permission
  Future<Map<String, dynamic>> assignPermission(AssignPermissionParams params);

  /// GET /admin/permissions - Get all permissions
  Future<List<AdminTrackingPermissionModel>> getAllPermissions();
}

class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final AuthenticatedApiClient apiClient;

  AdminRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<UserModel> createUser(CreateUserParams params) async {
    try {
      final response = await apiClient.dio.post(
        ApiEndpoints.adminUsers,
        data: params.toJson(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return UserModel.fromJson(response.data['user']);
      }
      throw Exception(response.data['error'] ?? 'Failed to create user');
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  @override
  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await apiClient.dio.get(ApiEndpoints.adminUsers);

      if (response.statusCode == 200) {
        final List<dynamic> usersJson = response.data['users'] ?? [];
        return usersJson.map((json) => UserModel.fromJson(json)).toList();
      }
      throw Exception(response.data['error'] ?? 'Failed to fetch users');
    } catch (e) {
      if (kDebugMode) {
        throw Exception('Failed to fetch users: $e');
      } else {
        throw Exception('Gagal mengambil daftar pengguna');
      }
    }
  }

  @override
  Future<void> deleteUser(String userId) async {
    try {
      final response =
          await apiClient.dio.delete(ApiEndpoints.adminUserById(userId));

      if (response.statusCode != 200) {
        throw Exception(response.data['error'] ?? 'Failed to delete user');
      }
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> assignPermission(
      AssignPermissionParams params) async {
    try {
      final response = await apiClient.dio.post(
        ApiEndpoints.adminPermissions,
        data: {
          'student_id': params.studentId,
          'lecturer_id': params.lecturerId,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      }
      throw Exception(response.data['error'] ?? 'Failed to assign permission');
    } catch (e) {
      throw Exception('Failed to assign permission: $e');
    }
  }

  @override
  Future<List<AdminTrackingPermissionModel>> getAllPermissions() async {
    try {
      final response = await apiClient.dio.get(ApiEndpoints.adminPermissions);

      if (response.statusCode == 200) {
        final List<dynamic> permissionsJson =
            response.data['permissions'] ?? [];
        return permissionsJson
            .map((json) => AdminTrackingPermissionModel.fromJson(json))
            .toList();
      }
      throw Exception(response.data['error'] ?? 'Failed to fetch permissions');
    } catch (e) {
      if (kDebugMode) {
        throw Exception('Failed to fetch permissions: $e');
      } else {
        throw Exception('Gagal mengambil daftar izin pelacakan');
      }
    }
  }
}
