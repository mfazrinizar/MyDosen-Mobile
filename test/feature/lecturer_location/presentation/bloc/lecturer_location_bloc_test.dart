import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mydosen/core/usecases/usecase.dart';
import 'package:mydosen/features/lecturer_location/domain/usecases/get_lecturer_location.dart';
import 'package:mydosen/features/lecturer_location/presentation/bloc/lecturer_location_bloc.dart';
import 'package:mydosen/features/lecturer_location/presentation/bloc/lecturer_location_event.dart';
import 'package:mydosen/features/lecturer_location/presentation/bloc/lecturer_location_state.dart';
import 'package:mydosen/features/lecturer_location/domain/entities/lecturer_location.dart';

class MockGetLecturerLocation extends Mock implements GetLecturerLocation {}

void main() {
  setUpAll(() {
    registerFallbackValue(NoParams());
  });

  late MockGetLecturerLocation mockUsecase;
  late LecturerLocationBloc bloc;

  setUp(() {
    mockUsecase = MockGetLecturerLocation();
    bloc = LecturerLocationBloc(getLecturerLocation: mockUsecase);
  });

  final sample = LecturerLocation(
      location: 'Kampus Indralaya', status: 'OK', updatedAt: DateTime.now());

  blocTest<LecturerLocationBloc, LecturerLocationState>(
    'emits [Loading, Loaded] when GetLecturerLocationEvent succeeds',
    setUp: () {
      when(() => mockUsecase(any())).thenAnswer((_) async => Right(sample));
    },
    build: () => bloc,
    act: (b) => b.add(GetLecturerLocationEvent()),
    expect: () =>
        [isA<LecturerLocationLoading>(), isA<LecturerLocationLoaded>()],
  );

  blocTest<LecturerLocationBloc, LecturerLocationState>(
    'emits RefreshedNoChange when refresh returns same location after loaded',
    setUp: () {
      when(() => mockUsecase(any())).thenAnswer((_) async => Right(sample));
    },
    build: () => bloc,
    act: (b) async {
      b.add(GetLecturerLocationEvent());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      b.add(RefreshLecturerLocationEvent());
    },
    expect: () => [
      isA<LecturerLocationLoading>(),
      isA<LecturerLocationLoaded>(),
      isA<LecturerLocationRefreshedNoChange>()
    ],
  );
}
