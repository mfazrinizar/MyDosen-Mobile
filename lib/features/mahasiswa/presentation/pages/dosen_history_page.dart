import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/mahasiswa_bloc.dart';
import '../bloc/mahasiswa_event.dart';
import '../bloc/mahasiswa_state.dart';
import '../../domain/entities/tracking_entities.dart';

class DosenHistoryPage extends StatefulWidget {
  final String dosenId;
  final String dosenName;

  const DosenHistoryPage({
    super.key,
    required this.dosenId,
    required this.dosenName,
  });

  @override
  State<DosenHistoryPage> createState() => _DosenHistoryPageState();
}

class _DosenHistoryPageState extends State<DosenHistoryPage> {
  @override
  void initState() {
    super.initState();
    context.read<MahasiswaBloc>().add(LoadDosenHistoryEvent(widget.dosenId));
  }

  Future<void> _onRefresh() async {
    context.read<MahasiswaBloc>().add(LoadDosenHistoryEvent(widget.dosenId));
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Riwayat Lokasi',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              widget.dosenName,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
      body: BlocConsumer<MahasiswaBloc, MahasiswaState>(
        listener: (context, state) {
          if (state is MahasiswaError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is MahasiswaLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryOrange,
              ),
            );
          }

          if (state is DosenHistoryLoaded) {
            return _buildHistoryContent(state.history);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildHistoryContent(LocationHistory history) {
    if (history.history.isEmpty) {
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
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada riwayat lokasi',
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
        itemCount: history.history.length,
        itemBuilder: (context, index) {
          final dayHistory = history.history[index];
          return _DayHistoryCard(dayHistory: dayHistory)
              .animate(delay: Duration(milliseconds: 100 * index))
              .fadeIn()
              .slideY(begin: 0.1, duration: 300.ms);
        },
      ),
    );
  }
}

class _DayHistoryCard extends StatefulWidget {
  final DayHistory dayHistory;

  const _DayHistoryCard({required this.dayHistory});

  @override
  State<_DayHistoryCard> createState() => _DayHistoryCardState();
}

class _DayHistoryCardState extends State<_DayHistoryCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final dayName = widget.dayHistory.dayName;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.calendar_today,
                      color: AppTheme.primaryOrange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Hari ke-${widget.dayHistory.dayOfWeek}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${widget.dayHistory.logs.length} lokasi',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: _buildLogs(),
          ),
        ],
      ),
    );
  }

  Widget _buildLogs() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(12),
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widget.dayHistory.logs.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          indent: 56,
          color: Colors.grey[300],
        ),
        itemBuilder: (context, index) {
          final log = widget.dayHistory.logs[index];
          return _LogItem(log: log);
        },
      ),
    );
  }
}

class _LogItem extends StatelessWidget {
  final LocationLog log;

  const _LogItem({required this.log});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on,
              size: 16,
              color: AppTheme.primaryOrange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.locationName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      log.loggedAt != null ? _formatTime(log.loggedAt!) : '-',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${log.latitude.toStringAsFixed(6)}, ${log.longitude.toStringAsFixed(6)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
