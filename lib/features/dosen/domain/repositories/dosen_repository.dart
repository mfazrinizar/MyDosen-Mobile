import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/dosen_entities.dart';

abstract class DosenRepository {
  /// Get pending tracking requests from Mahasiswa
  Future<Either<Failure, List<TrackingRequest>>> getPendingRequests();

  /// Handle (approve/reject) a tracking request
  Future<Either<Failure, Map<String, dynamic>>> handleRequest({
    required String permissionId,
    required String action, // 'approved' or 'rejected'
  });

  /// Get Dosen's own location history
  Future<Either<Failure, List<DosenLocationHistory>>> getOwnHistory();

  /// Get list of students with approved tracking permission
  Future<Either<Failure, List<ApprovedStudent>>> getApprovedStudents();

  /// Get list of students who can track this dosen
  Future<Either<Failure, List<TrackingStudent>>> getTrackingStudents();
}
