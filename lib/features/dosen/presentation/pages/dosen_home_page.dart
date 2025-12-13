import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/background_location_service.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/dosen_bloc.dart';
import '../bloc/dosen_event.dart';
import '../bloc/dosen_state.dart';

class DosenHomePage extends StatefulWidget {
  const DosenHomePage({super.key});

  @override
  State<DosenHomePage> createState() => _DosenHomePageState();
}

class _DosenHomePageState extends State<DosenHomePage> {
  late LocationService _locationService;
  final BackgroundLocationManager _backgroundManager =
      BackgroundLocationManager();
  bool _isLiveTracking = false;
  bool _isBackgroundServiceRunning = false;
  bool _isSendingLocation = false;
  double? _lastLatitude;
  double? _lastLongitude;
  String? _currentPositionName;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _locationService = di.sl<LocationService>();

    // Initialize live tracking state on app startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DosenBloc>().add(InitializeLiveTrackingEvent());
      _checkBackgroundServiceStatus();
    });
  }

  Future<void> _checkBackgroundServiceStatus() async {
    final isRunning = await _backgroundManager.isServiceRunning();
    if (mounted) {
      setState(() {
        _isBackgroundServiceRunning = isRunning;
      });
    }
  }

  Future<void> _sendLocationOnce() async {
    if (_isSendingLocation) return;

    setState(() {
      _isSendingLocation = true;
    });

    try {
      final position = await _locationService.getCurrentPosition();
      if (position != null && mounted) {
        context.read<DosenBloc>().add(SendLocationOnceEvent(
              latitude: position.latitude,
              longitude: position.longitude,
            ));
        setState(() {
          _lastLatitude = position.latitude;
          _lastLongitude = position.longitude;
          _lastUpdated = DateTime.now();
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mendapatkan lokasi. Periksa izin GPS.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingLocation = false;
        });
      }
    }
  }

  void _toggleLiveTracking() {
    if (_isLiveTracking) {
      context.read<DosenBloc>().add(StopLiveTrackingEvent());
    } else {
      context.read<DosenBloc>().add(StartLiveTrackingEvent());
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AuthBloc>().add(LogoutEvent());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showBackgroundPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (context) => AlertDialog(
        title: const Text('Izin Lokasi Latar Belakang'),
        content: const Text(
          'Untuk melanjutkan tracking lokasi saat aplikasi ditutup, Anda perlu memberikan izin "Izinkan sepanjang waktu". '
          'Tanpa izin ini, tracking hanya akan berjalan saat aplikasi terbuka.\n\n'
          'Pilih "Buka Pengaturan" untuk memberikan izin, atau "Lanjutkan" untuk tracking foreground saja.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Continue with foreground-only tracking
              context.read<DosenBloc>().add(ContinueWithForegroundOnlyEvent());
            },
            child: const Text('Lanjutkan'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Open settings to grant background permission
              context
                  .read<DosenBloc>()
                  .add(OpenBackgroundPermissionSettingsEvent());
            },
            child: const Text('Buka Pengaturan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is LogoutSuccess || state is Unauthenticated) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.login);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.asset(
                  'assets/images/icon-full.png',
                  width: 25,
                  height: 25,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 8),
              const Text('MyDosen'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: _logout,
            ),
          ],
        ),
        body: BlocConsumer<DosenBloc, DosenState>(
          listener: (context, state) {
            if (state is LocationUpdateSuccess) {
              setState(() {
                _isSendingLocation = false;
                if (state.positionName != null) {
                  _currentPositionName = state.positionName;
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.positionName != null
                      ? '${state.message} (${state.positionName})'
                      : state.message),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is LiveTrackingStatus) {
              setState(() {
                _isLiveTracking = state.isTracking;
                if (state.lastLatitude != null) {
                  _lastLatitude = state.lastLatitude;
                }
                if (state.lastLongitude != null) {
                  _lastLongitude = state.lastLongitude;
                }
                if (state.lastUpdated != null) {
                  _lastUpdated = state.lastUpdated;
                }
                if (state.positionName != null) {
                  _currentPositionName = state.positionName;
                }
              });
              // Check background service status
              _checkBackgroundServiceStatus();
            } else if (state is DosenError) {
              setState(() {
                _isSendingLocation = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is BackgroundPermissionDenied) {
              // Show dialog for background permission choice
              _showBackgroundPermissionDialog(context);
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 16),
                  _buildLocationButtons(state),
                  const SizedBox(height: 24),
                  _buildMenuGrid(),
                ]
                    .animate(interval: 100.ms)
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.1),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isLiveTracking
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _isLiveTracking ? Icons.location_on : Icons.location_off,
                    color: _isLiveTracking ? Colors.green : Colors.orange,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status Tracking',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  _isLiveTracking ? Colors.green : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isLiveTracking
                                ? 'Live Tracking Aktif'
                                : 'Tidak Aktif',
                            style: TextStyle(
                              color: _isLiveTracking
                                  ? Colors.green
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (_isLiveTracking) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              _isBackgroundServiceRunning
                                  ? Icons.cloud_sync
                                  : Icons.phone_android,
                              size: 12,
                              color: _isBackgroundServiceRunning
                                  ? Colors.blue[400]
                                  : Colors.orange[400],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isBackgroundServiceRunning
                                  ? 'Background service aktif'
                                  : 'Foreground tracking aktif',
                              style: TextStyle(
                                color: _isBackgroundServiceRunning
                                    ? Colors.blue[400]
                                    : Colors.orange[400],
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (_lastLatitude != null && _lastLongitude != null) ...[
              const Divider(height: 24),
              if (_currentPositionName != null &&
                  _currentPositionName!.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.location_on,
                        size: 16, color: AppTheme.primaryOrange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _currentPositionName!,
                        style: const TextStyle(
                          color: AppTheme.primaryOrange,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              Row(
                children: [
                  Icon(Icons.pin_drop, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 8),
                  Text(
                    '${_lastLatitude!.toStringAsFixed(6)}, ${_lastLongitude!.toStringAsFixed(6)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              if (_lastUpdated != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 8),
                    Text(
                      'Terakhir diperbarui: ${_formatTime(_lastUpdated!)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationButtons(DosenState state) {
    final isLoading = state is DosenLoading;

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed:
                _isSendingLocation || isLoading ? null : _sendLocationOnce,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: _isSendingLocation
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send),
            label: Text(_isSendingLocation ? 'Mengirim...' : 'Kirim Sekali'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : _toggleLiveTracking,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isLiveTracking ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(_isLiveTracking ? Icons.stop : Icons.play_arrow),
            label: Text(_isLiveTracking ? 'Stop Live' : 'Start Live'),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Menu',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _buildMenuCard(
              icon: Icons.pending_actions,
              title: 'Permintaan Tracking',
              color: Colors.blue,
              onTap: () {
                Navigator.of(context).pushNamed(AppRoutes.dosenRequests);
              },
            ),
            _buildMenuCard(
              icon: Icons.history,
              title: 'Riwayat Lokasi',
              color: Colors.purple,
              onTap: () {
                Navigator.of(context).pushNamed(AppRoutes.dosenOwnHistory);
              },
            ),
            _buildMenuCard(
              icon: Icons.map,
              title: 'Lihat di Peta',
              color: Colors.teal,
              onTap: () {
                if (_lastLatitude != null && _lastLongitude != null) {
                  Navigator.of(context).pushNamed(
                    AppRoutes.dosenMapView,
                    arguments: {
                      'latitude': _lastLatitude,
                      'longitude': _lastLongitude,
                      'positionName': _currentPositionName,
                    },
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Belum ada data lokasi'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
            ),
            _buildMenuCard(
              icon: Icons.people,
              title: 'Mahasiswa Diizinkan',
              color: Colors.indigo,
              onTap: () {
                Navigator.of(context).pushNamed(AppRoutes.dosenStudents);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }
}
