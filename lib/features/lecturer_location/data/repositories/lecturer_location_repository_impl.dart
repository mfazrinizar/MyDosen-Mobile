import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/lecturer_location.dart';
import '../../domain/repositories/lecturer_location_repository.dart';
import '../datasources/lecturer_location_remote_data_source.dart';

class LecturerLocationRepositoryImpl implements LecturerLocationRepository {
  final LecturerLocationRemoteDataSource remoteDataSource;

  LecturerLocationRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, LecturerLocation>> getLecturerLocation() async {
    try {
      final result = await remoteDataSource.getLecturerLocation();
      return Right(result);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return const Left(NetworkFailure('Tidak ada koneksi internet'));
      }
      return Left(ServerFailure(e.message ?? 'Server error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
