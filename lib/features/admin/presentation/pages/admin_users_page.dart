import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';
import '../../domain/entities/admin_entities.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedRole;
  List<User> _cachedUsers = [];

  @override
  void initState() {
    super.initState();
    context.read<AdminBloc>().add(LoadUsersEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    context.read<AdminBloc>().add(LoadUsersEvent());
    await Future.delayed(const Duration(seconds: 1));
  }

  void _deleteUser(User user) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus User'),
        content: Text(
          'Apakah Anda yakin ingin menghapus ${user.name}?\n\n'
          'Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<AdminBloc>().add(DeleteUserEvent(
                    userId: user.id,
                    userName: user.name,
                  ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Pengguna'),
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: BlocConsumer<AdminBloc, AdminState>(
              listener: (context, state) {
                if (state is UsersLoaded) {
                  _cachedUsers = state.filteredUsers;
                } else if (state is UserDeleted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.green,
                    ),
                  );
                  context.read<AdminBloc>().add(LoadUsersEvent());
                } else if (state is AdminError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is AdminLoading && _cachedUsers.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primaryOrange),
                  );
                }

                final users =
                    state is UsersLoaded ? state.filteredUsers : _cachedUsers;

                if (users.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _onRefresh,
                    color: AppTheme.primaryOrange,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Tidak ada pengguna',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: AppTheme.primaryOrange,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return _UserCard(
                        user: user,
                        onDelete: () => _deleteUser(user),
                      )
                          .animate(delay: Duration(milliseconds: 30 * index))
                          .fadeIn()
                          .slideX(begin: 0.1, duration: 200.ms);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari pengguna...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: (value) {
              context.read<AdminBloc>().add(SearchUsersEvent(value));
            },
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Semua', null),
                const SizedBox(width: 8),
                _buildFilterChip('Admin', 'admin'),
                const SizedBox(width: 8),
                _buildFilterChip('Dosen', 'dosen'),
                const SizedBox(width: 8),
                _buildFilterChip('Mahasiswa', 'mahasiswa'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? role) {
    final isSelected = _selectedRole == role;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedRole = selected ? role : null;
        });
        context.read<AdminBloc>().add(FilterUsersByRoleEvent(role));
      },
      selectedColor: AppTheme.primaryOrange.withValues(alpha: 0.2),
      checkmarkColor: AppTheme.primaryOrange,
    );
  }
}

class _UserCard extends StatelessWidget {
  final User user;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.onDelete,
  });

  Color get _roleColor {
    switch (user.role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'dosen':
        return Colors.blue;
      case 'mahasiswa':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _roleColor.withValues(alpha: 0.2),
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: _roleColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        user.email,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _roleColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.roleLabel,
                    style: TextStyle(
                      color: _roleColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.badge, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 8),
                Text(
                  user.roleIdentifier,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const Spacer(),
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text(
                  DateTimeUtils.formatDate(user.createdAt),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Hapus'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
