import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mydosen/core/error/failures.dart';
import 'package:mydosen/core/usecases/usecase.dart';
import 'package:mydosen/features/lecturer_location/domain/repositories/lecturer_location_repository.dart';
import 'package:mydosen/features/lecturer_location/domain/usecases/get_lecturer_location.dart';
import 'package:mydosen/features/lecturer_location/domain/entities/lecturer_location.dart';

class MockRepository extends Mock implements LecturerLocationRepository {}

void main() {
  late MockRepository mockRepo;
  late GetLecturerLocation usecase;

  setUp(() {
    mockRepo = MockRepository();
    usecase = GetLecturerLocation(mockRepo);
  });

  final entity = LecturerLocation(
      location: 'Kampus Indralaya', status: 'OK', updatedAt: DateTime.now());

  test('calls repository and returns data', () async {
    when(() => mockRepo.getLecturerLocation())
        .thenAnswer((_) async => Right(entity));

    final res = await usecase(NoParams());

    expect(res.isRight(), true);
    verify(() => mockRepo.getLecturerLocation()).called(1);
  });

  test('propagates failure', () async {
    when(() => mockRepo.getLecturerLocation())
        .thenAnswer((_) async => Left(ServerFailure('err')));

    final res = await usecase(NoParams());

    expect(res.isLeft(), true);
  });
}
