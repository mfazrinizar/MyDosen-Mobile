import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../domain/entities/tracking_entities.dart';

class DosenLocationCard extends StatelessWidget {
  final DosenLocation dosen;
  final VoidCallback onTap;
  final VoidCallback onHistoryTap;

  const DosenLocationCard({
    super.key,
    required this.dosen,
    required this.onTap,
    required this.onHistoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildAvatar(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dosen.name,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        _buildOnlineStatus(),
                      ],
                    ),
                  ),
                  _buildActionButtons(context),
                ],
              ),
              const SizedBox(height: 12),
              _buildLocationInfo(context),
              if (dosen.lastUpdated != null) ...[
                const SizedBox(height: 8),
                _buildLastUpdated(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.primaryOrange.withValues(alpha: 0.2),
        border: Border.all(
          color: dosen.isOnline ? Colors.green : Colors.grey,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          _getInitials(dosen.name),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryOrange,
          ),
        ),
      ),
    );
  }

  Widget _buildOnlineStatus() {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dosen.isOnline ? Colors.green : Colors.grey,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          dosen.isOnline ? 'Online' : 'Offline',
          style: TextStyle(
            fontSize: 12,
            color: dosen.isOnline ? Colors.green : Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.history, size: 20),
          tooltip: 'Riwayat Lokasi',
          onPressed: onHistoryTap,
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey.withValues(alpha: 0.1),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.map, size: 20),
          tooltip: 'Lihat di Peta',
          onPressed: onTap,
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.primaryOrange.withValues(alpha: 0.1),
            foregroundColor: AppTheme.primaryOrange,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationInfo(BuildContext context) {
    if (dosen.latitude == null || dosen.longitude == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.location_off, size: 18, color: Colors.grey),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Lokasi belum tersedia',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_on,
            size: 18,
            color: AppTheme.primaryOrange,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dosen.positionName ?? 'Posisi tidak diketahui',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${dosen.latitude!.toStringAsFixed(6)}, ${dosen.longitude!.toStringAsFixed(6)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastUpdated(BuildContext context) {
    final lastUpdated = dosen.lastUpdated;
    if (lastUpdated == null) return const SizedBox.shrink();

    return Row(
      children: [
        Icon(
          Icons.access_time,
          size: 14,
          color: Colors.grey[500],
        ),
        const SizedBox(width: 4),
        Text(
          'Diperbarui ${DateTimeUtils.formatRelative(lastUpdated)}',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
          ),
        ),
      ],
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
