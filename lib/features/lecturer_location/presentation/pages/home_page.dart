import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/lecturer_location_bloc.dart';
import '../bloc/lecturer_location_event.dart';
import '../bloc/lecturer_location_state.dart';
import '../widgets/loading_shimmer.dart';
import '../widgets/location_info_card.dart';
import '../widgets/location_map_widget.dart';
import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/theme/theme_event.dart';
import '../../../../core/theme/theme_state.dart';
import '../../../../core/navigation/app_router.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late ScrollController _scrollController;
  bool _isScrolled = false;
  final GlobalKey _mapKey = GlobalKey();
  bool _dragOverMap = false;

  void _safeSetState(VoidCallback fn) {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle) {
      if (!mounted) return;
      setState(fn);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(fn);
      });
    }
  }

  void _safeShowSnackBar(SnackBar snackBar) {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      });
    }
  }

  void _checkDrag(Offset position, bool up) {
    if (up) {
      if (_dragOverMap) _safeSetState(() => _dragOverMap = false);
      return;
    }
    try {
      final ctx = _mapKey.currentContext;
      if (ctx == null) return;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null) return;
      final boxOffset = box.localToGlobal(Offset.zero);
      final size = box.size;
      final inside = position.dx > boxOffset.dx &&
          position.dx < boxOffset.dx + size.width &&
          position.dy > boxOffset.dy &&
          position.dy < boxOffset.dy + size.height;
      if (inside != _dragOverMap) _safeSetState(() => _dragOverMap = inside);
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    context.read<LecturerLocationBloc>().add(GetLecturerLocationEvent());
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      final collapsedThreshold = 120 - kToolbarHeight;
      final scrolled = _scrollController.hasClients &&
          _scrollController.offset > collapsedThreshold;
      if (scrolled != _isScrolled) _safeSetState(() => _isScrolled = scrolled);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    context.read<LecturerLocationBloc>().add(RefreshLecturerLocationEvent());
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppTheme.primaryOrange,
        // Solution for Map widget, in this case OSMFlutter, to be interactive
        // Inside ScrollView:
        // Wrap with Listener to detect pointer position relative to the map
        // and disable parent scrolling while dragging over the map.
        child: Listener(
          onPointerDown: (ev) => _checkDrag(ev.position, false),
          onPointerMove: (ev) => _checkDrag(ev.position, false),
          onPointerUp: (ev) => _checkDrag(ev.position, true),
          behavior: HitTestBehavior.translucent,
          child: CustomScrollView(
            controller: _scrollController,
            physics: _dragOverMap
                ? const NeverScrollableScrollPhysics()
                : const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
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
                      Text(
                        'MyDosen',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          letterSpacing: 0.5,
                          color: _isScrolled
                              ? AppTheme.primaryOrange
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
                  background: ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(20),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryOrange,
                            AppTheme.secondaryOrange,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  BlocBuilder<ThemeBloc, ThemeState>(
                    builder: (context, themeState) {
                      final isDark = themeState is ThemeLoaded
                          ? themeState.isDark
                          : Theme.of(context).brightness == Brightness.dark;
                      return IconButton(
                        icon: Icon(
                          isDark
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          color: _isScrolled
                              ? AppTheme.primaryOrange
                              : Colors.white,
                        ),
                        onPressed: () {
                          context.read<ThemeBloc>().add(ToggleThemeEvent());
                        },
                      );
                    },
                  ),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isScrolled
                            ? AppTheme.secondaryOrange.withValues(alpha: 0.1)
                            : Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.info_outline_rounded,
                        color:
                            _isScrolled ? AppTheme.primaryOrange : Colors.white,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.about);
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              SliverToBoxAdapter(
                child:
                    BlocConsumer<LecturerLocationBloc, LecturerLocationState>(
                  listenWhen: (previous, current) {
                    if (current is LecturerLocationError) return true;
                    if (previous is LecturerLocationLoaded &&
                        current is LecturerLocationRefreshedNoChange) {
                      return true;
                    }
                    return false;
                  },
                  listener: (context, state) {
                    if (state is LecturerLocationError) {
                      _safeShowSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.white),
                              const SizedBox(width: 12),
                              Expanded(child: Text(state.message)),
                            ],
                          ),
                          backgroundColor: Colors.red.shade400,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.all(16),
                        ),
                      );
                    } else if (state is LecturerLocationRefreshedNoChange) {
                      _safeShowSnackBar(
                        SnackBar(
                          content: const Text('Berhasil refresh...'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.all(16),
                        ),
                      );
                    }
                  },
                  builder: (context, state) {
                    if (state is LecturerLocationLoading) {
                      return const LoadingShimmer();
                    }

                    if (state is LecturerLocationLoaded ||
                        state is LecturerLocationRefreshedNoChange) {
                      final location = state is LecturerLocationLoaded
                          ? state.location
                          : (state as LecturerLocationRefreshedNoChange)
                              .location;

                      return ListView(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        children: [
                          Container(
                            key: _mapKey,
                            height: MediaQuery.of(context).size.height * 0.45,
                            margin: const EdgeInsets.only(left: 20, right: 20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryOrange
                                      .withValues(alpha: 0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: LocationMapWidget(
                              location: location.location,
                            )
                                .animate()
                                .fadeIn(duration: 950.ms, curve: Curves.easeOut)
                                .slideY(begin: 0.05, end: 0, duration: 1000.ms),
                          ),
                          LocationInfoCard(location: location)
                              .animate()
                              .fadeIn(duration: 950.ms, curve: Curves.easeOut)
                              .slideY(begin: 0.05, end: 0, duration: 1000.ms),
                          const SizedBox(height: 100), // Space for FAB
                        ],
                      );
                    }

                    return SizedBox(
                      height: MediaQuery.of(context).size.height - 200,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryOrange
                                    .withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.error_outline_rounded,
                                size: 64,
                                color: AppTheme.primaryOrange,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Gagal memuat data',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Silakan coba lagi',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () {
                                context
                                    .read<LecturerLocationBloc>()
                                    .add(GetLecturerLocationEvent());
                              },
                              icon: const Icon(Icons.refresh_rounded,
                                  color: Colors.white),
                              label: const Text('Coba Lagi'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton:
          BlocBuilder<LecturerLocationBloc, LecturerLocationState>(
        builder: (context, state) {
          if (state is LecturerLocationLoaded ||
              state is LecturerLocationRefreshedNoChange) {
            return FloatingActionButton(
              onPressed: () {
                context
                    .read<LecturerLocationBloc>()
                    .add(RefreshLecturerLocationEvent());
              },
              tooltip: 'Refresh',
              child: const Icon(Icons.refresh_rounded),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
