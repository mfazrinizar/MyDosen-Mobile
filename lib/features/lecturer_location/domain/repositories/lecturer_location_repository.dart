import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/lecturer_location.dart';

abstract class LecturerLocationRepository {
  Future<Either<Failure, LecturerLocation>> getLecturerLocation();
}
