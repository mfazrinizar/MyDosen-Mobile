import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../bloc/dosen_bloc.dart';
import '../bloc/dosen_event.dart';
import '../bloc/dosen_state.dart';
import '../../domain/entities/dosen_entities.dart';

class DosenRequestsPage extends StatefulWidget {
  const DosenRequestsPage({super.key});

  @override
  State<DosenRequestsPage> createState() => _DosenRequestsPageState();
}

class _DosenRequestsPageState extends State<DosenRequestsPage> {
  List<TrackingRequest> _cachedRequests = [];

  @override
  void initState() {
    super.initState();
    context.read<DosenBloc>().add(LoadPendingRequestsEvent());
  }

  Future<void> _onRefresh() async {
    context.read<DosenBloc>().add(LoadPendingRequestsEvent());
    await Future.delayed(const Duration(seconds: 1));
  }

  void _handleRequest(TrackingRequest request, String action) {
    final isApprove = action == 'approved';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isApprove ? 'Setujui Permintaan' : 'Tolak Permintaan'),
        content: Text(
          isApprove
              ? 'Setujui permintaan tracking dari ${request.studentName}?'
              : 'Tolak permintaan tracking dari ${request.studentName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (isApprove) {
                context.read<DosenBloc>().add(ApproveRequestEvent(
                      permissionId: request.id,
                      studentName: request.studentName,
                    ));
              } else {
                context.read<DosenBloc>().add(RejectRequestEvent(
                      permissionId: request.id,
                      studentName: request.studentName,
                    ));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isApprove ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(isApprove ? 'Setujui' : 'Tolak'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permintaan Tracking'),
      ),
      body: BlocConsumer<DosenBloc, DosenState>(
        listener: (context, state) {
          if (state is PendingRequestsLoaded) {
            _cachedRequests = state.requests;
          } else if (state is RequestHandled) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.action == 'approved'
                      ? 'Permintaan dari ${state.studentName} disetujui'
                      : 'Permintaan dari ${state.studentName} ditolak',
                ),
                backgroundColor:
                    state.action == 'approved' ? Colors.green : Colors.orange,
              ),
            );
            // Reload requests after handling
            context.read<DosenBloc>().add(LoadPendingRequestsEvent());
          } else if (state is DosenError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is DosenLoading && _cachedRequests.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryOrange),
            );
          }

          final requests =
              state is PendingRequestsLoaded ? state.requests : _cachedRequests;

          if (requests.isEmpty) {
            return RefreshIndicator(
              onRefresh: _onRefresh,
              color: AppTheme.primaryOrange,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak Ada Permintaan',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Belum ada mahasiswa yang mengajukan permintaan tracking.',
                          textAlign: TextAlign.center,
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
                return _RequestCard(
                  request: request,
                  onApprove: () => _handleRequest(request, 'approved'),
                  onReject: () => _handleRequest(request, 'rejected'),
                )
                    .animate(delay: Duration(milliseconds: 50 * index))
                    .fadeIn()
                    .slideX(begin: 0.1, duration: 200.ms);
              },
            ),
          );
        },
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final TrackingRequest request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _RequestCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

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
                  backgroundColor:
                      AppTheme.primaryOrange.withValues(alpha: 0.2),
                  child: Text(
                    request.studentName.isNotEmpty
                        ? request.studentName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppTheme.primaryOrange,
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
                        request.studentName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'NIM: ${request.nim}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.email_outlined, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    request.studentEmail,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 8),
                Text(
                  DateTimeUtils.formatRelative(request.createdAt),
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Tolak'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Setujui'),
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
