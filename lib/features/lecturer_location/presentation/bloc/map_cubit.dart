import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import '../mappers/location_presentation.dart';

part 'map_state.dart';

class MapCubit extends Cubit<MapState> {
  final MapController mapController;

  // Default initial center (Indonesia)
  static final GeoPoint defaultCenter =
      GeoPoint(latitude: -2.5, longitude: 118.0);

  MapCubit({MapController? controller})
      : mapController =
            controller ?? MapController(initPosition: defaultCenter),
        super(const MapState.initial());

  Future<void> setTarget(LocationPresentation target) async {
    emit(const MapState.initial()); // go to loading
    await _setupMap(target);
  }

  Future<void> setTargetFromString(String location) async {
    final target = LocationPresentation.fromLocationString(location);
    await setTarget(target);
  }

  Future<void> _setupMap(LocationPresentation target,
      {double circleRadius = 250}) async {
    try {
      await mapController.setZoom(zoomLevel: target.zoom);
      await mapController.moveTo(target.point);
      await Future.delayed(const Duration(milliseconds: 300));

      await mapController.addMarker(
        target.point,
        markerIcon: MarkerIcon(
          icon: Icon(Icons.location_on, color: target.color, size: 108),
        ),
      );

      if (target.drawCircle) {
        try {
          await mapController.drawCircle(
            CircleOSM(
              key: 'location_circle',
              centerPoint: target.point,
              radius: circleRadius,
              color: target.color.withValues(alpha: 0.2),
              strokeWidth: 3,
            ),
          );
        } catch (_) {}
      }

      emit(const MapState.ready());
    } catch (e) {
      emit(MapState.error(e.toString()));
    }
  }

  Future<void> zoomIn() async {
    try {
      await mapController.zoomIn();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('MapCubit.zoomIn error: $e\n$st');
      }
    }
  }

  Future<void> zoomOut() async {
    try {
      await mapController.zoomOut();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('MapCubit.zoomOut error: $e\n$st');
      }
    }
  }

  Future<void> goTo(GeoPoint target, double zoom) async {
    try {
      await mapController.moveTo(target);
      await mapController.setZoom(zoomLevel: zoom);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('MapCubit.goTo error: $e\n$st');
      }
    }
  }

  // void reset() => emit(const MapState.initial());

  @override
  Future<void> close() {
    try {
      mapController.dispose();
    } catch (_) {}
    return super.close();
  }
}
