import 'package:equatable/equatable.dart';
import '../../domain/entities/admin_entities.dart';

abstract class AdminEvent extends Equatable {
  const AdminEvent();

  @override
  List<Object?> get props => [];
}

/// Load all users
class LoadUsersEvent extends AdminEvent {}

/// Create a new user
class CreateUserEvent extends AdminEvent {
  final CreateUserParams params;

  const CreateUserEvent(this.params);

  @override
  List<Object?> get props => [params];
}

/// Delete a user
class DeleteUserEvent extends AdminEvent {
  final String userId;
  final String userName;

  const DeleteUserEvent({
    required this.userId,
    required this.userName,
  });

  @override
  List<Object?> get props => [userId, userName];
}

/// Load all permissions
class LoadPermissionsEvent extends AdminEvent {}

/// Assign permission
class AssignPermissionEvent extends AdminEvent {
  final AssignPermissionParams params;
  final String studentName;
  final String lecturerName;

  const AssignPermissionEvent({
    required this.params,
    required this.studentName,
    required this.lecturerName,
  });

  @override
  List<Object?> get props => [params, studentName, lecturerName];
}

/// Filter users by role
class FilterUsersByRoleEvent extends AdminEvent {
  final String? role; // null means all

  const FilterUsersByRoleEvent(this.role);

  @override
  List<Object?> get props => [role];
}

/// Search users
class SearchUsersEvent extends AdminEvent {
  final String query;

  const SearchUsersEvent(this.query);

  @override
  List<Object?> get props => [query];
}
