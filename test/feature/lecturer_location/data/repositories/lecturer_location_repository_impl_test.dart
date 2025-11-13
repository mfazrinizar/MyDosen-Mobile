import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mydosen/core/error/failures.dart';
import 'package:mydosen/features/lecturer_location/data/datasources/lecturer_location_remote_data_source.dart';
import 'package:mydosen/features/lecturer_location/data/repositories/lecturer_location_repository_impl.dart';
import 'package:mydosen/features/lecturer_location/data/models/lecturer_location_model.dart';

class MockRemoteDataSource extends Mock
    implements LecturerLocationRemoteDataSource {}

void main() {
  late MockRemoteDataSource mockRemote;
  late LecturerLocationRepositoryImpl repository;

  setUp(() {
    mockRemote = MockRemoteDataSource();
    repository = LecturerLocationRepositoryImpl(remoteDataSource: mockRemote);
  });

  final model = LecturerLocationModel(
    location: 'Kampus Palembang',
    status: 'OK',
    updatedAt: DateTime.parse('2024-01-01T00:00:00Z'),
  );

  test('returns Right(LecturerLocation) when remote succeeds', () async {
    when(() => mockRemote.getLecturerLocation()).thenAnswer((_) async => model);

    final res = await repository.getLecturerLocation();

    expect(res.isRight(), true);
  });

  test('returns NetworkFailure on connection timeout', () async {
    when(() => mockRemote.getLecturerLocation()).thenThrow(
      DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionTimeout),
    );

    final res = await repository.getLecturerLocation();

    expect(res.isLeft(), true);
    res.fold((l) => expect(l, isA<NetworkFailure>()), (_) {});
  });

  test('returns ServerFailure on other DioException', () async {
    when(() => mockRemote.getLecturerLocation()).thenThrow(
      DioException(
          requestOptions: RequestOptions(path: ''),
          error: 'server',
          type: DioExceptionType.badResponse),
    );

    final res = await repository.getLecturerLocation();

    expect(res.isLeft(), true);
    res.fold((l) => expect(l, isA<ServerFailure>()), (_) {});
  });
}
