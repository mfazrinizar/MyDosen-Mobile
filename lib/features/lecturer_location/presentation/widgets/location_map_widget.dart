import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/map_cubit.dart';
import '../mappers/location_presentation.dart';

class LocationMapWidget extends StatefulWidget {
  final String location;

  const LocationMapWidget({
    super.key,
    required this.location,
  });

  @override
  State<LocationMapWidget> createState() => _LocationMapWidgetState();
}

class _LocationMapWidgetState extends State<LocationMapWidget> {
  bool _mapReady = false;
  bool _pendingSetup = false;

  void _onMapReady() {
    if (!mounted) return;
    setState(() {
      _mapReady = true;
    });

    final cubit = context.read<MapCubit>();
    // delegate mapping & setup to cubit
    cubit.setTargetFromString(widget.location);

    if (_pendingSetup) {
      _pendingSetup = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // cubit.reset();
        cubit.setTargetFromString(widget.location);
      });
    }
  }

  @override
  void didUpdateWidget(LocationMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) {
      final cubit = context.read<MapCubit>();
      // cubit.reset();
      if (_mapReady) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          cubit.setTargetFromString(widget.location);
        });
      } else {
        _pendingSetup = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cubit = context.read<MapCubit>();
    final presentation =
        LocationPresentation.fromLocationString(widget.location);

    return Stack(
      children: [
        OSMFlutter(
          controller: cubit.mapController,
          onMapIsReady: (isReady) {
            if (isReady && !_mapReady) _onMapReady();
          },
          osmOption: OSMOption(
            zoomOption: const ZoomOption(
                initZoom: 16.5,
                minZoomLevel: 3,
                maxZoomLevel: 19,
                stepZoom: 1.0),
            staticPoints: [],
            roadConfiguration: const RoadOption(roadColor: Colors.blue),
            showDefaultInfoWindow: true,
            enableRotationByGesture: true,
          ),
          mapIsLoading: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                      shape: BoxShape.circle),
                  child: const CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppTheme.primaryOrange),
                      strokeWidth: 3),
                ),
                const SizedBox(height: 20),
                Text('Memuat peta...',
                    style: TextStyle(
                        color: AppTheme.primaryOrange,
                        fontWeight: FontWeight.w600,
                        fontSize: 16)),
              ],
            ),
          ),
        ),
        // Controls
        Positioned(
          right: 16,
          bottom: 16,
          child: Column(
            children: [
              _buildControlButton(
                  icon: Icons.add_rounded,
                  onPressed: () => cubit.zoomIn(),
                  tooltip: 'Zoom In',
                  isDark: isDark),
              const SizedBox(height: 8),
              _buildControlButton(
                  icon: Icons.remove_rounded,
                  onPressed: () => cubit.zoomOut(),
                  tooltip: 'Zoom Out',
                  isDark: isDark),
              const SizedBox(height: 8),
              _buildControlButton(
                  icon: Icons.my_location_rounded,
                  onPressed: () =>
                      cubit.goTo(presentation.point, presentation.zoom),
                  tooltip: 'Ke Lokasi',
                  isDark: isDark,
                  isPrimary: true),
            ],
          ),
        ),
        // Overlay + label (driven by MapCubit state)
        BlocBuilder<MapCubit, MapState>(
          builder: (context, mapState) {
            if (!_mapReady || !mapState.ready) {
              return Positioned.fill(
                child: Container(
                  color: (isDark ? Colors.black : Colors.white)
                      .withValues(alpha: 0.8),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color:
                                AppTheme.primaryOrange.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryOrange),
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('Memuat peta...',
                            style: TextStyle(
                                color: AppTheme.primaryOrange,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              );
            }

            if (widget.location.isNotEmpty) {
              return Positioned(
                left: 16,
                top: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      presentation.color,
                      presentation.color.withValues(alpha: 0.85)
                    ]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(presentation.icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(widget.location,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                  ]),
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    required bool isDark,
    bool isPrimary = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: isPrimary
                  ? const LinearGradient(colors: [
                      AppTheme.primaryOrange,
                      AppTheme.secondaryOrange
                    ], begin: Alignment.topLeft, end: Alignment.bottomRight)
                  : null,
              color:
                  isPrimary ? null : (isDark ? Colors.grey[850] : Colors.white),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isPrimary
                    ? AppTheme.primaryOrange.withValues(alpha: 0.3)
                    : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                    color: isPrimary
                        ? AppTheme.primaryOrange.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Icon(icon,
                color: isPrimary
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.grey[800]),
                size: 24),
          ),
        ),
      ),
    );
  }
}
