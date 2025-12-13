import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../bloc/mahasiswa_bloc.dart';
import '../bloc/mahasiswa_event.dart';
import '../bloc/mahasiswa_state.dart';
import '../../domain/entities/tracking_entities.dart';

class MyRequestsPage extends StatefulWidget {
  const MyRequestsPage({super.key});

  @override
  State<MyRequestsPage> createState() => _MyRequestsPageState();
}

class _MyRequestsPageState extends State<MyRequestsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<TrackingPermission> _cachedRequests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<MahasiswaBloc>().add(LoadMyRequestsEvent());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    context.read<MahasiswaBloc>().add(LoadMyRequestsEvent());
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permintaan Saya'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Menunggu'),
            Tab(text: 'Disetujui'),
            Tab(text: 'Ditolak'),
          ],
        ),
      ),
      body: BlocConsumer<MahasiswaBloc, MahasiswaState>(
        listener: (context, state) {
          if (state is MyRequestsLoaded) {
            _cachedRequests = state.requests;
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
          // Show loading only when actually loading requests
          if (state is MahasiswaLoading && _cachedRequests.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryOrange,
              ),
            );
          }

          // Use cached data or current state data
          final requests =
              state is MyRequestsLoaded ? state.requests : _cachedRequests;

          final pending = requests
              .where((r) => r.status.toLowerCase() == 'pending')
              .toList();
          final approved = requests
              .where((r) => r.status.toLowerCase() == 'approved')
              .toList();
          final rejected = requests
              .where((r) => r.status.toLowerCase() == 'rejected')
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildRequestList(pending, 'pending'),
              _buildRequestList(approved, 'approved'),
              _buildRequestList(rejected, 'rejected'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRequestList(List<TrackingPermission> requests, String type) {
    if (requests.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppTheme.primaryOrange,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getEmptyIcon(type),
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getEmptyMessage(type),
                    style: TextStyle(color: Colors.grey[600]),
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
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          return _RequestCard(request: request)
              .animate(delay: Duration(milliseconds: 50 * index))
              .fadeIn()
              .slideX(begin: 0.1, duration: 200.ms);
        },
      ),
    );
  }

  IconData _getEmptyIcon(String type) {
    switch (type) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'approved':
        return Icons.check_circle_outline;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.inbox;
    }
  }

  String _getEmptyMessage(String type) {
    switch (type) {
      case 'pending':
        return 'Tidak ada permintaan yang menunggu';
      case 'approved':
        return 'Belum ada permintaan yang disetujui';
      case 'rejected':
        return 'Tidak ada permintaan yang ditolak';
      default:
        return 'Tidak ada data';
    }
  }
}

class _RequestCard extends StatelessWidget {
  final TrackingPermission request;

  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryOrange.withValues(alpha: 0.2),
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(request.lecturerName ?? ''),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryOrange,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.lecturerName ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (request.lecturerNidn != null)
                        Text(
                          'NIDN: ${request.lecturerNidn}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
                _buildStatusBadge(request.status),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            if (request.createdAt != null)
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Diajukan: ${DateTimeUtils.formatForDisplay(request.createdAt!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}
