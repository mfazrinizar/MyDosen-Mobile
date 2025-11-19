import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:flutter/foundation.dart';
import 'package:mydosen/features/lecturer_location/presentation/bloc/map_cubit.dart';

class MockMapController extends Mock implements MapController {}

class FakeGeoPoint extends Fake implements GeoPoint {}

class FakeMarkerIcon extends Fake implements MarkerIcon {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      super.toString();
}

class FakeCircleOSM extends Fake implements CircleOSM {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeGeoPoint());
    registerFallbackValue(FakeMarkerIcon());
    registerFallbackValue(FakeCircleOSM());
  });

  late MockMapController mockController;

  setUp(() {
    mockController = MockMapController();
  });

  blocTest<MapCubit, MapState>(
    'emits [initial, ready] when setTargetFromString succeeds',
    build: () {
      // stub controller happy-path methods

      when(() => mockController.setZoom(zoomLevel: any(named: 'zoomLevel')))
          .thenAnswer((_) async {});
      when(() => mockController.moveTo(any())).thenAnswer((_) async {});
      when(() => mockController.addMarker(any(),
          markerIcon: any(named: 'markerIcon'))).thenAnswer((_) async {});
      when(() => mockController.drawCircle(any())).thenAnswer((_) async {});
      return MapCubit(controller: mockController);
    },
    act: (cubit) async {
      await cubit.setTargetFromString('Kampus Indralaya');
      // give async ops time
      await Future.delayed(const Duration(milliseconds: 20));
    },
    expect: () => [const MapState.initial(), const MapState.ready()],
    verify: (_) {
      verify(() => mockController.addMarker(any(),
          markerIcon: any(named: 'markerIcon'))).called(1);
    },
  );

  blocTest<MapCubit, MapState>(
    'emits [initial, error] when addMarker throws',
    build: () {
      when(() => mockController.setZoom(zoomLevel: any(named: 'zoomLevel')))
          .thenAnswer((_) async {});
      when(() => mockController.moveTo(any())).thenAnswer((_) async {});
      when(() => mockController.addMarker(any(),
              markerIcon: any(named: 'markerIcon')))
          .thenThrow(Exception('marker failed'));
      return MapCubit(controller: mockController);
    },
    act: (cubit) async {
      await cubit.setTargetFromString('Kampus Palembang');
      await Future.delayed(const Duration(milliseconds: 20));
    },
    expect: () => [
      const MapState.initial(),
      predicate<MapState>((s) => s.error != null && s.error!.isNotEmpty)
    ],
  );

  test('zoomIn/zoomOut delegate to controller', () async {
    when(() => mockController.zoomIn()).thenAnswer((_) async {});
    when(() => mockController.zoomOut()).thenAnswer((_) async {});
    final cubit = MapCubit(controller: mockController);

    await cubit.zoomIn();
    await cubit.zoomOut();

    verify(() => mockController.zoomIn()).called(1);
    verify(() => mockController.zoomOut()).called(1);
    await cubit.close();
  });
}
