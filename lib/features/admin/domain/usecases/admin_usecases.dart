import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/admin_entities.dart';
import '../repositories/admin_repository.dart';

/// Create a new user
class CreateUser implements UseCase<User, CreateUserParams> {
  final AdminRepository repository;

  CreateUser(this.repository);

  @override
  Future<Either<Failure, User>> call(CreateUserParams params) {
    return repository.createUser(params);
  }
}

/// Get all users
class GetAllUsers implements UseCase<List<User>, NoParams> {
  final AdminRepository repository;

  GetAllUsers(this.repository);

  @override
  Future<Either<Failure, List<User>>> call(NoParams params) {
    return repository.getAllUsers();
  }
}

/// Delete a user
class DeleteUser implements UseCase<void, String> {
  final AdminRepository repository;

  DeleteUser(this.repository);

  @override
  Future<Either<Failure, void>> call(String userId) {
    return repository.deleteUser(userId);
  }
}

/// Assign permission (force create/update)
class AssignPermission
    implements UseCase<Map<String, dynamic>, AssignPermissionParams> {
  final AdminRepository repository;

  AssignPermission(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(
      AssignPermissionParams params) {
    return repository.assignPermission(params);
  }
}

/// Get all permissions
class GetAllPermissions
    implements UseCase<List<AdminTrackingPermission>, NoParams> {
  final AdminRepository repository;

  GetAllPermissions(this.repository);

  @override
  Future<Either<Failure, List<AdminTrackingPermission>>> call(NoParams params) {
    return repository.getAllPermissions();
  }
}
