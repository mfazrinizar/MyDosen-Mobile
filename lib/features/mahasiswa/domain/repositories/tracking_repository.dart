import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/tracking_entities.dart';

abstract class TrackingRepository {
  /// Get list of all dosen for requesting access
  Future<Either<Failure, List<DosenInfo>>> getAllDosen();

  /// Request tracking access to a dosen
  Future<Either<Failure, Map<String, dynamic>>> requestAccess(
      String lecturerId);

  /// Get mahasiswa's tracking requests
  Future<Either<Failure, List<TrackingPermission>>> getMyRequests();

  /// Get list of dosen that mahasiswa has approved access to
  Future<Either<Failure, List<DosenLocation>>> getAllowedDosen();

  /// Get location history of a dosen
  Future<Either<Failure, LocationHistory>> getDosenHistory(String dosenId);
}
