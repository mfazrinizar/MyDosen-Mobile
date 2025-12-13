import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/mahasiswa_bloc.dart';
import '../bloc/mahasiswa_event.dart';
import '../bloc/mahasiswa_state.dart';
import '../../domain/entities/tracking_entities.dart';

class DosenListPage extends StatefulWidget {
  const DosenListPage({super.key});

  @override
  State<DosenListPage> createState() => _DosenListPageState();
}

class _DosenListPageState extends State<DosenListPage> {
  final TextEditingController _searchController = TextEditingController();
  List<DosenInfo> _filteredDosen = [];
  List<DosenInfo> _allDosen = [];

  @override
  void initState() {
    super.initState();
    context.read<MahasiswaBloc>().add(LoadAllDosenEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterDosen(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredDosen = _allDosen;
      } else {
        _filteredDosen = _allDosen.where((dosen) {
          final nameLower = dosen.name.toLowerCase();
          final nidnLower = dosen.nidn.toLowerCase();
          final searchLower = query.toLowerCase();
          return nameLower.contains(searchLower) ||
              nidnLower.contains(searchLower);
        }).toList();
      }
    });
  }

  void _requestAccess(DosenInfo dosen) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ajukan Tracking'),
        content: Text(
          'Anda akan mengajukan permintaan tracking untuk:\n\n'
          '${dosen.name}\n'
          'NIDN: ${dosen.nidn}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<MahasiswaBloc>().add(
                    RequestAccessEvent(dosen.userId),
                  );
            },
            child: const Text('Ajukan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Dosen'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari dosen...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterDosen('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: _filterDosen,
            ),
          ),
          Expanded(
            child: BlocConsumer<MahasiswaBloc, MahasiswaState>(
              listener: (context, state) {
                if (state is DosenListLoaded) {
                  setState(() {
                    _allDosen = state.dosenList;
                    _filteredDosen = state.dosenList;
                  });
                } else if (state is RequestAccessSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.green,
                    ),
                  );
                  // Refresh the list to update status
                  context.read<MahasiswaBloc>().add(LoadAllDosenEvent());
                } else if (state is MahasiswaError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is MahasiswaLoading && _allDosen.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryOrange,
                    ),
                  );
                }

                if (_filteredDosen.isEmpty &&
                    _searchController.text.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada hasil untuk "${_searchController.text}"',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                if (_filteredDosen.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_search,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada dosen tersedia',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredDosen.length,
                  itemBuilder: (context, index) {
                    final dosen = _filteredDosen[index];
                    return _DosenListItem(
                      dosen: dosen,
                      onRequestAccess: () => _requestAccess(dosen),
                    )
                        .animate(delay: Duration(milliseconds: 50 * index))
                        .fadeIn()
                        .slideX(
                          begin: 0.1,
                          duration: 200.ms,
                        );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DosenListItem extends StatelessWidget {
  final DosenInfo dosen;
  final VoidCallback onRequestAccess;

  const _DosenListItem({
    required this.dosen,
    required this.onRequestAccess,
  });

  @override
  Widget build(BuildContext context) {
    final status = dosen.requestStatus;
    final hasExistingRequest = status != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primaryOrange.withValues(alpha: 0.2),
          ),
          child: Center(
            child: Text(
              _getInitials(dosen.name),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryOrange,
              ),
            ),
          ),
        ),
        title: Text(
          dosen.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('NIDN: ${dosen.nidn}'),
        trailing: hasExistingRequest
            ? _buildStatusChip(status)
            : ElevatedButton(
                onPressed: onRequestAccess,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text('Ajukan'),
              ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'approved':
        backgroundColor = Colors.green.withValues(alpha: 0.2);
        textColor = Colors.green[700]!;
        label = 'Disetujui';
        icon = Icons.check_circle;
        break;
      case 'pending':
        backgroundColor = Colors.orange.withValues(alpha: 0.2);
        textColor = Colors.orange[700]!;
        label = 'Menunggu';
        icon = Icons.hourglass_empty;
        break;
      case 'rejected':
        backgroundColor = Colors.red.withValues(alpha: 0.2);
        textColor = Colors.red[700]!;
        label = 'Ditolak';
        icon = Icons.cancel;
        break;
      default:
        backgroundColor = Colors.grey.withValues(alpha: 0.2);
        textColor = Colors.grey[700]!;
        label = status;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
