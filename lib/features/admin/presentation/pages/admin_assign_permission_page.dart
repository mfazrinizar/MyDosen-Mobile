import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../mahasiswa/domain/usecases/tracking_usecases.dart';
import '../../../mahasiswa/domain/entities/tracking_entities.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';
import '../../domain/entities/admin_entities.dart';
import '../../../../core/di/injection_container.dart' as di;

class AdminAssignPermissionPage extends StatefulWidget {
  const AdminAssignPermissionPage({super.key});

  @override
  State<AdminAssignPermissionPage> createState() =>
      _AdminAssignPermissionPageState();
}

class _AdminAssignPermissionPageState extends State<AdminAssignPermissionPage> {
  User? _selectedStudent;
  User? _selectedLecturer;
  List<User> _students = [];
  List<User> _lecturers = [];
  List<DosenInfo> _dosenList = [];
  bool _isLoading = false;
  bool _isAssigning = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Load users
    context.read<AdminBloc>().add(LoadUsersEvent());

    // Also load dosen list for reference
    try {
      final getAllDosen = di.sl<GetAllDosen>();
      final result = await getAllDosen(NoParams());
      result.fold(
        (_) {},
        (dosen) {
          if (mounted) {
            setState(() {
              _dosenList = dosen;
            });
          }
        },
      );
    } catch (_) {}

    setState(() => _isLoading = false);
  }

  void _assignPermission() {
    if (_selectedStudent == null || _selectedLecturer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih mahasiswa dan dosen terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: Text(
          'Tetapkan izin tracking:\n\n'
          'Mahasiswa: ${_selectedStudent!.name}\n'
          'Dosen: ${_selectedLecturer!.name}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              setState(() => _isAssigning = true);
              context.read<AdminBloc>().add(AssignPermissionEvent(
                    params: AssignPermissionParams(
                      studentId: _selectedStudent!.id,
                      lecturerId: _selectedLecturer!.id,
                    ),
                    studentName: _selectedStudent!.name,
                    lecturerName: _selectedLecturer!.name,
                  ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryOrange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tetapkan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tetapkan Izin'),
      ),
      body: BlocConsumer<AdminBloc, AdminState>(
        listener: (context, state) {
          if (state is UsersLoaded) {
            setState(() {
              _students = state.users
                  .where((u) => u.role.toLowerCase() == 'mahasiswa')
                  .toList();
              _lecturers = state.users
                  .where((u) => u.role.toLowerCase() == 'dosen')
                  .toList();
              _isAssigning = false; // Reset loading state when users loaded
            });
          } else if (state is PermissionAssigned) {
            setState(() => _isAssigning = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Izin berhasil ditetapkan untuk ${state.studentName} → ${state.lecturerName}',
                ),
                backgroundColor: Colors.green,
              ),
            );
            setState(() {
              _selectedStudent = null;
              _selectedLecturer = null;
            });
          } else if (state is AdminError) {
            setState(() => _isAssigning = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (_isLoading && _students.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryOrange),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSelectionCard(
                  title: 'Pilih Mahasiswa',
                  icon: Icons.school,
                  selectedUser: _selectedStudent,
                  users: _students,
                  onSelect: (user) => setState(() => _selectedStudent = user),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_downward,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildSelectionCard(
                  title: 'Pilih Dosen',
                  icon: Icons.person,
                  selectedUser: _selectedLecturer,
                  users: _lecturers,
                  onSelect: (user) => setState(() => _selectedLecturer = user),
                  dosenList: _dosenList,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: (_selectedStudent != null &&
                          _selectedLecturer != null &&
                          !_isAssigning)
                      ? _assignPermission
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isAssigning
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Tetapkan Izin',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Catatan: Izin yang ditetapkan akan langsung aktif (status: approved)',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectionCard({
    required String title,
    required IconData icon,
    required User? selectedUser,
    required List<User> users,
    required Function(User?) onSelect,
    List<DosenInfo>? dosenList,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppTheme.primaryOrange),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (selectedUser != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedUser.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            selectedUser.email,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => onSelect(null), // Clear selection
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => _showUserPicker(users, onSelect, dosenList),
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Ganti'),
              ),
            ] else
              InkWell(
                onTap: () => _showUserPicker(users, onSelect, dosenList),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.add_circle_outline,
                            color: Colors.grey[400], size: 32),
                        const SizedBox(height: 8),
                        Text(
                          'Tap untuk memilih',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showUserPicker(
    List<User> users,
    Function(User?) onSelect,
    List<DosenInfo>? dosenList,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Cari...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  // Could implement filtering
                },
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(user.name[0].toUpperCase()),
                    ),
                    title: Text(user.name),
                    subtitle: Text('${user.email}\n${user.roleIdentifier}'),
                    isThreeLine: true,
                    onTap: () {
                      onSelect(user);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
