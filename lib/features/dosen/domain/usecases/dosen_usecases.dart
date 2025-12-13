import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/dosen_entities.dart';
import '../repositories/dosen_repository.dart';

/// Get pending tracking requests
class GetPendingRequests implements UseCase<List<TrackingRequest>, NoParams> {
  final DosenRepository repository;

  GetPendingRequests(this.repository);

  @override
  Future<Either<Failure, List<TrackingRequest>>> call(NoParams params) {
    return repository.getPendingRequests();
  }
}

/// Handle tracking request parameters
class HandleRequestParams {
  final String permissionId;
  final String action;

  HandleRequestParams({
    required this.permissionId,
    required this.action,
  });
}

/// Handle (approve/reject) tracking request
class HandleTrackingRequest
    implements UseCase<Map<String, dynamic>, HandleRequestParams> {
  final DosenRepository repository;

  HandleTrackingRequest(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(
      HandleRequestParams params) {
    return repository.handleRequest(
      permissionId: params.permissionId,
      action: params.action,
    );
  }
}

/// Get Dosen's own location history
class GetOwnHistory implements UseCase<List<DosenLocationHistory>, NoParams> {
  final DosenRepository repository;

  GetOwnHistory(this.repository);

  @override
  Future<Either<Failure, List<DosenLocationHistory>>> call(NoParams params) {
    return repository.getOwnHistory();
  }
}

/// Get approved students
class GetApprovedStudents implements UseCase<List<ApprovedStudent>, NoParams> {
  final DosenRepository repository;

  GetApprovedStudents(this.repository);

  @override
  Future<Either<Failure, List<ApprovedStudent>>> call(NoParams params) {
    return repository.getApprovedStudents();
  }
}

/// Get students who can track this dosen
class GetTrackingStudents implements UseCase<List<TrackingStudent>, NoParams> {
  final DosenRepository repository;

  GetTrackingStudents(this.repository);

  @override
  Future<Either<Failure, List<TrackingStudent>>> call(NoParams params) {
    return repository.getTrackingStudents();
  }
}
