import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/lecturer_location.dart';
import '../repositories/lecturer_location_repository.dart';

class GetLecturerLocation implements UseCase<LecturerLocation, NoParams> {
  final LecturerLocationRepository repository;

  GetLecturerLocation(this.repository);

  @override
  Future<Either<Failure, LecturerLocation>> call(NoParams params) async {
    return await repository.getLecturerLocation();
  }
}
