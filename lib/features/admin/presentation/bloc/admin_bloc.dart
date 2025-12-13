import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/admin_entities.dart';
import '../../domain/usecases/admin_usecases.dart';
import 'admin_event.dart';
import 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final CreateUser createUser;
  final GetAllUsers getAllUsers;
  final DeleteUser deleteUser;
  final AssignPermission assignPermission;
  final GetAllPermissions getAllPermissions;

  List<User> _allUsers = [];

  AdminBloc({
    required this.createUser,
    required this.getAllUsers,
    required this.deleteUser,
    required this.assignPermission,
    required this.getAllPermissions,
  }) : super(AdminInitial()) {
    on<LoadUsersEvent>(_onLoadUsers);
    on<CreateUserEvent>(_onCreateUser);
    on<DeleteUserEvent>(_onDeleteUser);
    on<LoadPermissionsEvent>(_onLoadPermissions);
    on<AssignPermissionEvent>(_onAssignPermission);
    on<FilterUsersByRoleEvent>(_onFilterUsers);
    on<SearchUsersEvent>(_onSearchUsers);
  }

  Future<void> _onLoadUsers(
    LoadUsersEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());

    final result = await getAllUsers(NoParams());

    result.fold(
      (failure) => emit(AdminError(failure.message)),
      (users) {
        _allUsers = users;
        emit(UsersLoaded(users: users, filteredUsers: users));
      },
    );
  }

  Future<void> _onCreateUser(
    CreateUserEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());

    final result = await createUser(event.params);

    result.fold(
      (failure) => emit(AdminError(failure.message)),
      (user) => emit(UserCreated(
        user: user,
        message: 'User ${user.name} berhasil dibuat',
      )),
    );
  }

  Future<void> _onDeleteUser(
    DeleteUserEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());

    final result = await deleteUser(event.userId);

    result.fold(
      (failure) => emit(AdminError(failure.message)),
      (_) => emit(UserDeleted(
        userId: event.userId,
        userName: event.userName,
        message: 'User ${event.userName} berhasil dihapus',
      )),
    );
  }

  Future<void> _onLoadPermissions(
    LoadPermissionsEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());

    final result = await getAllPermissions(NoParams());

    result.fold(
      (failure) => emit(AdminError(failure.message)),
      (permissions) => emit(PermissionsLoaded(permissions)),
    );
  }

  Future<void> _onAssignPermission(
    AssignPermissionEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());

    final result = await assignPermission(event.params);

    result.fold(
      (failure) => emit(AdminError(failure.message)),
      (response) => emit(PermissionAssigned(
        message: response['message'] ?? 'Permission berhasil ditetapkan',
        studentName: event.studentName,
        lecturerName: event.lecturerName,
      )),
    );
  }

  void _onFilterUsers(
    FilterUsersByRoleEvent event,
    Emitter<AdminState> emit,
  ) {
    if (state is UsersLoaded) {
      final currentState = state as UsersLoaded;
      List<User> filtered;

      if (event.role == null || event.role!.isEmpty) {
        filtered = _allUsers;
      } else {
        filtered = _allUsers
            .where((u) => u.role.toLowerCase() == event.role!.toLowerCase())
            .toList();
      }

      // Apply existing search if any
      if (currentState.searchQuery.isNotEmpty) {
        filtered = filtered
            .where((u) =>
                u.name
                    .toLowerCase()
                    .contains(currentState.searchQuery.toLowerCase()) ||
                u.email
                    .toLowerCase()
                    .contains(currentState.searchQuery.toLowerCase()))
            .toList();
      }

      emit(currentState.copyWith(
        filteredUsers: filtered,
        currentFilter: event.role,
      ));
    }
  }

  void _onSearchUsers(
    SearchUsersEvent event,
    Emitter<AdminState> emit,
  ) {
    if (state is UsersLoaded) {
      final currentState = state as UsersLoaded;
      List<User> filtered = _allUsers;

      // Apply role filter if any
      if (currentState.currentFilter != null &&
          currentState.currentFilter!.isNotEmpty) {
        filtered = filtered
            .where((u) =>
                u.role.toLowerCase() ==
                currentState.currentFilter!.toLowerCase())
            .toList();
      }

      // Apply search
      if (event.query.isNotEmpty) {
        filtered = filtered
            .where((u) =>
                u.name.toLowerCase().contains(event.query.toLowerCase()) ||
                u.email.toLowerCase().contains(event.query.toLowerCase()) ||
                u.roleIdentifier
                    .toLowerCase()
                    .contains(event.query.toLowerCase()))
            .toList();
      }

      emit(currentState.copyWith(
        filteredUsers: filtered,
        searchQuery: event.query,
      ));
    }
  }
}
