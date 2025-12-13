import 'package:equatable/equatable.dart';
import '../../domain/entities/admin_entities.dart';

abstract class AdminState extends Equatable {
  const AdminState();

  @override
  List<Object?> get props => [];
}

class AdminInitial extends AdminState {}

class AdminLoading extends AdminState {}

/// State for loaded users
class UsersLoaded extends AdminState {
  final List<User> users;
  final List<User> filteredUsers;
  final String? currentFilter;
  final String searchQuery;

  const UsersLoaded({
    required this.users,
    required this.filteredUsers,
    this.currentFilter,
    this.searchQuery = '',
  });

  UsersLoaded copyWith({
    List<User>? users,
    List<User>? filteredUsers,
    String? currentFilter,
    String? searchQuery,
  }) {
    return UsersLoaded(
      users: users ?? this.users,
      filteredUsers: filteredUsers ?? this.filteredUsers,
      currentFilter: currentFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [users, filteredUsers, currentFilter, searchQuery];
}

/// State for user created successfully
class UserCreated extends AdminState {
  final User user;
  final String message;

  const UserCreated({
    required this.user,
    required this.message,
  });

  @override
  List<Object?> get props => [user, message];
}

/// State for user deleted successfully
class UserDeleted extends AdminState {
  final String userId;
  final String userName;
  final String message;

  const UserDeleted({
    required this.userId,
    required this.userName,
    required this.message,
  });

  @override
  List<Object?> get props => [userId, userName, message];
}

/// State for loaded permissions
class PermissionsLoaded extends AdminState {
  final List<AdminTrackingPermission> permissions;

  const PermissionsLoaded(this.permissions);

  @override
  List<Object?> get props => [permissions];
}

/// State for permission assigned
class PermissionAssigned extends AdminState {
  final String message;
  final String studentName;
  final String lecturerName;

  const PermissionAssigned({
    required this.message,
    required this.studentName,
    required this.lecturerName,
  });

  @override
  List<Object?> get props => [message, studentName, lecturerName];
}

/// Error state
class AdminError extends AdminState {
  final String message;

  const AdminError(this.message);

  @override
  List<Object?> get props => [message];
}
