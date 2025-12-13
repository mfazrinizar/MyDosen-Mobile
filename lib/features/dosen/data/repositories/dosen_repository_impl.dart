import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/dosen_entities.dart';
import '../../domain/repositories/dosen_repository.dart';
import '../datasources/dosen_remote_data_source.dart';

class DosenRepositoryImpl implements DosenRepository {
  final DosenRemoteDataSource remoteDataSource;

  DosenRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<TrackingRequest>>> getPendingRequests() async {
    try {
      final requests = await remoteDataSource.getPendingRequests();
      return Right(requests);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> handleRequest({
    required String permissionId,
    required String action,
  }) async {
    try {
      final result = await remoteDataSource.handleRequest(
        permissionId: permissionId,
        action: action,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DosenLocationHistory>>> getOwnHistory() async {
    try {
      final history = await remoteDataSource.getOwnHistory();
      return Right(history);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ApprovedStudent>>> getApprovedStudents() async {
    // This can be derived from pending requests with 'approved' status
    // or we need a separate endpoint. For now, return empty.
    // The API doesn't have a dedicated endpoint for this,
    // we can get it from admin permissions endpoint if needed.
    return const Right([]);
  }

  @override
  Future<Either<Failure, List<TrackingStudent>>> getTrackingStudents() async {
    try {
      final students = await remoteDataSource.getTrackingStudents();
      return Right(students);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
