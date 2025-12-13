import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/admin_entities.dart';

abstract class AdminRepository {
  /// Create a new user
  Future<Either<Failure, User>> createUser(CreateUserParams params);

  /// Get all users
  Future<Either<Failure, List<User>>> getAllUsers();

  /// Delete a user
  Future<Either<Failure, void>> deleteUser(String userId);

  /// Create or update tracking permission (force assign)
  Future<Either<Failure, Map<String, dynamic>>> assignPermission(
      AssignPermissionParams params);

  /// Get all tracking permissions
  Future<Either<Failure, List<AdminTrackingPermission>>> getAllPermissions();
}
