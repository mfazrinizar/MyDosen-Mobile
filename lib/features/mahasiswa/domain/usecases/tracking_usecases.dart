import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/tracking_entities.dart';
import '../repositories/tracking_repository.dart';

/// Get all dosen for request list
class GetAllDosen implements UseCase<List<DosenInfo>, NoParams> {
  final TrackingRepository repository;

  GetAllDosen(this.repository);

  @override
  Future<Either<Failure, List<DosenInfo>>> call(NoParams params) async {
    return await repository.getAllDosen();
  }
}

/// Request tracking access to a dosen
class RequestTrackingAccess implements UseCase<Map<String, dynamic>, String> {
  final TrackingRepository repository;

  RequestTrackingAccess(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(String lecturerId) async {
    return await repository.requestAccess(lecturerId);
  }
}

/// Get mahasiswa's tracking requests
class GetMyRequests implements UseCase<List<TrackingPermission>, NoParams> {
  final TrackingRepository repository;

  GetMyRequests(this.repository);

  @override
  Future<Either<Failure, List<TrackingPermission>>> call(
      NoParams params) async {
    return await repository.getMyRequests();
  }
}

/// Get allowed dosen list with locations
class GetAllowedDosen implements UseCase<List<DosenLocation>, NoParams> {
  final TrackingRepository repository;

  GetAllowedDosen(this.repository);

  @override
  Future<Either<Failure, List<DosenLocation>>> call(NoParams params) async {
    return await repository.getAllowedDosen();
  }
}

/// Get dosen location history
class GetDosenHistory implements UseCase<LocationHistory, String> {
  final TrackingRepository repository;

  GetDosenHistory(this.repository);

  @override
  Future<Either<Failure, LocationHistory>> call(String dosenId) async {
    return await repository.getDosenHistory(dosenId);
  }
}
