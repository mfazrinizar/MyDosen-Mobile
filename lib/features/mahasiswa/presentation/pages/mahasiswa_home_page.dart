import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/mahasiswa_bloc.dart';
import '../bloc/mahasiswa_event.dart';
import '../bloc/mahasiswa_state.dart';
import '../widgets/dosen_location_card.dart';

class MahasiswaHomePage extends StatefulWidget {
  const MahasiswaHomePage({super.key});

  @override
  State<MahasiswaHomePage> createState() => _MahasiswaHomePageState();
}

class _MahasiswaHomePageState extends State<MahasiswaHomePage>
    with WidgetsBindingObserver {
  late SocketService _socketService;
  StreamSubscription? _dosenMovedSubscription;
  StreamSubscription? _dosenStatusSubscription;
  final Set<String> _joinedRooms = {};
  List<dynamic> _cachedDosenList = [];

  @override
  void initState() {
    super.initState();
    _socketService = di.sl<SocketService>();
    _initializeSocket();
    _loadData();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }

  void _initializeSocket() async {
    await _socketService.connect();

    _dosenMovedSubscription = _socketService.onDosenMoved.listen((update) {
      if (mounted) {
        context.read<MahasiswaBloc>().add(UpdateDosenLocationEvent(
              dosenId: update.dosenId,
              latitude: update.latitude,
              longitude: update.longitude,
              positionName: update.positionName,
              lastUpdated: update.lastUpdated,
            ));
      }
    });

    _dosenStatusSubscription = _socketService.onDosenStatus.listen((update) {
      if (mounted) {
        context.read<MahasiswaBloc>().add(UpdateDosenStatusEvent(
              dosenId: update.dosenId,
              isOnline: update.isOnline,
            ));
      }
    });
  }

  void _loadData() {
    context.read<MahasiswaBloc>().add(LoadAllowedDosenEvent());
  }

  void _joinDosenRooms(List<String> dosenIds) {
    for (final dosenId in dosenIds) {
      if (!_joinedRooms.contains(dosenId)) {
        _socketService.joinDosenRoom(dosenId);
        _joinedRooms.add(dosenId);
      }
    }
  }

  Future<void> _onRefresh() async {
    context.read<MahasiswaBloc>().add(RefreshAllowedDosenEvent());
    await Future.delayed(const Duration(seconds: 1));
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dosenMovedSubscription?.cancel();
    _dosenStatusSubscription?.cancel();
    for (final dosenId in _joinedRooms) {
      _socketService.leaveDosenRoom(dosenId);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is LogoutSuccess || state is Unauthenticated) {
          Navigator.of(context).pushNamed(AppRoutes.login);
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
              icon: const Icon(Icons.person_add_outlined),
              tooltip: 'Ajukan Tracking',
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.dosenList).then((_) {
                  if (mounted) _loadData();
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'Riwayat Permintaan',
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.myRequests).then((_) {
                  if (mounted) _loadData();
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: _logout,
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppTheme.primaryOrange,
          child: BlocConsumer<MahasiswaBloc, MahasiswaState>(
            listener: (context, state) {
              if (state is AllowedDosenLoaded) {
                // Join rooms for all allowed dosen
                final dosenIds = state.dosenList.map((d) => d.userId).toList();
                _joinDosenRooms(dosenIds);
                _cachedDosenList = state.dosenList;
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
              // Show loading only when actually loading and no cache
              if (state is MahasiswaLoading && _cachedDosenList.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryOrange,
                  ),
                );
              }

              // Use cached data or current state data
              final dosenList = state is AllowedDosenLoaded
                  ? state.dosenList
                  : _cachedDosenList;

              if (dosenList.isEmpty) {
                return _buildEmptyState();
              }
              return _buildDosenList(dosenList);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off_outlined,
              size: 80,
              color: AppTheme.primaryOrange.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Dosen',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Anda belum memiliki izin untuk melacak lokasi dosen. '
              'Ajukan permintaan tracking terlebih dahulu.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.dosenList);
              },
              icon: const Icon(Icons.add),
              label: const Text('Ajukan Tracking'),
            ),
          ],
        ).animate().fadeIn(duration: 500.ms),
      ),
    );
  }

  Widget _buildDosenList(List dosenList) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: dosenList.length,
      itemBuilder: (context, index) {
        final dosen = dosenList[index];
        return DosenLocationCard(
          dosen: dosen,
          onTap: () {
            Navigator.of(context).pushNamed(
              AppRoutes.trackingMap,
              arguments: {
                'dosenId': dosen.userId,
                'dosenName': dosen.name,
                'latitude': dosen.latitude,
                'longitude': dosen.longitude,
                'positionName': dosen.positionName,
                'isOnline': dosen.isOnline,
              },
            );
          },
          onHistoryTap: () {
            Navigator.of(context).pushNamed(
              AppRoutes.dosenHistory,
              arguments: {
                'dosenId': dosen.userId,
                'dosenName': dosen.name,
              },
            );
          },
        ).animate(delay: Duration(milliseconds: 100 * index)).fadeIn().slideX(
              begin: 0.1,
              duration: 300.ms,
            );
      },
    );
  }
}
