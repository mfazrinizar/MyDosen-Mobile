import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../bloc/dosen_bloc.dart';
import '../bloc/dosen_event.dart';
import '../bloc/dosen_state.dart';
import '../../domain/entities/dosen_entities.dart';

class DosenOwnHistoryPage extends StatefulWidget {
  const DosenOwnHistoryPage({super.key});

  @override
  State<DosenOwnHistoryPage> createState() => _DosenOwnHistoryPageState();
}

class _DosenOwnHistoryPageState extends State<DosenOwnHistoryPage> {
  List<DosenLocationHistory> _cachedHistory = [];

  @override
  void initState() {
    super.initState();
    context.read<DosenBloc>().add(LoadOwnHistoryEvent());
  }

  Future<void> _onRefresh() async {
    context.read<DosenBloc>().add(LoadOwnHistoryEvent());
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Lokasi Saya'),
      ),
      body: BlocConsumer<DosenBloc, DosenState>(
        listener: (context, state) {
          if (state is OwnHistoryLoaded) {
            _cachedHistory = state.history;
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
          if (state is DosenLoading && _cachedHistory.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryOrange),
            );
          }

          final history =
              state is OwnHistoryLoaded ? state.history : _cachedHistory;

          if (history.isEmpty) {
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
                          Icons.history,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum Ada Riwayat',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Riwayat lokasi akan muncul setelah Anda membagikan lokasi.',
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
              itemCount: history.length,
              itemBuilder: (context, index) {
                final dayHistory = history[index];
                return _DayHistoryCard(history: dayHistory)
                    .animate(delay: Duration(milliseconds: 50 * index))
                    .fadeIn()
                    .slideY(begin: 0.1, duration: 200.ms);
              },
            ),
          );
        },
      ),
    );
  }
}

class _DayHistoryCard extends StatelessWidget {
  final DosenLocationHistory history;

  const _DayHistoryCard({required this.history});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      history.dayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${history.logs.length} lokasi tercatat',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Logs
          if (history.logs.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Tidak ada log untuk hari ini',
                style: TextStyle(color: Colors.grey[600]),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: history.logs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final log = history.logs[index];
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.blue,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    log.locationName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${log.latitude.toStringAsFixed(6)}, ${log.longitude.toStringAsFixed(6)}',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        DateTimeUtils.formatTime(log.loggedAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                );
              },
            ),
        ],
      ),
    );
  }
}
