import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user.dart';

abstract class AuthRepository {
  /// Login with email and password
  /// Returns [User] on success, [Failure] on error
  Future<Either<Failure, User>> login(String email, String password);

  /// Get current user profile
  /// Returns [User] on success, [Failure] on error
  Future<Either<Failure, User>> getProfile();

  /// Logout - clear stored credentials
  Future<Either<Failure, void>> logout();

  /// Check if user is logged in
  Future<bool> isLoggedIn();

  /// Get stored user role
  Future<String?> getUserRole();
}
