import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/tracking_entities.dart';
import '../../domain/repositories/tracking_repository.dart';
import '../datasources/tracking_remote_data_source.dart';

class TrackingRepositoryImpl implements TrackingRepository {
  final TrackingRemoteDataSource remoteDataSource;

  TrackingRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<DosenInfo>>> getAllDosen() async {
    try {
      final result = await remoteDataSource.getAllDosen();
      return Right(result);
    } on DioException catch (e) {
      return Left(ServerFailure(
          e.response?.data?['error'] ?? 'Gagal mengambil daftar dosen'));
    } catch (e) {
      return Left(NetworkFailure('Tidak dapat terhubung ke server: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> requestAccess(
      String lecturerId) async {
    try {
      final result = await remoteDataSource.requestAccess(lecturerId);
      return Right(result);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return const Left(ServerFailure('Dosen tidak ditemukan'));
      } else if (e.response?.statusCode == 409) {
        return const Left(ServerFailure('Permintaan sudah pernah diajukan'));
      }
      return Left(ServerFailure(
          e.response?.data?['error'] ?? 'Gagal mengajukan permintaan'));
    } catch (e) {
      return Left(NetworkFailure('Tidak dapat terhubung ke server: $e'));
    }
  }

  @override
  Future<Either<Failure, List<TrackingPermission>>> getMyRequests() async {
    try {
      final result = await remoteDataSource.getMyRequests();
      return Right(result);
    } on DioException catch (e) {
      return Left(ServerFailure(
          e.response?.data?['error'] ?? 'Gagal mengambil daftar permintaan'));
    } catch (e) {
      return Left(NetworkFailure('Tidak dapat terhubung ke server: $e'));
    }
  }

  @override
  Future<Either<Failure, List<DosenLocation>>> getAllowedDosen() async {
    try {
      final result = await remoteDataSource.getAllowedDosen();
      return Right(result);
    } on DioException catch (e) {
      return Left(ServerFailure(
          e.response?.data?['error'] ?? 'Gagal mengambil daftar dosen'));
    } catch (e) {
      return Left(NetworkFailure('Tidak dapat terhubung ke server: $e'));
    }
  }

  @override
  Future<Either<Failure, LocationHistory>> getDosenHistory(
      String dosenId) async {
    try {
      final result = await remoteDataSource.getDosenHistory(dosenId);
      return Right(result);
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        return const Left(ServerFailure(
            'Anda tidak memiliki izin untuk melihat riwayat ini'));
      }
      return Left(ServerFailure(
          e.response?.data?['error'] ?? 'Gagal mengambil riwayat lokasi'));
    } catch (e) {
      return Left(NetworkFailure('Tidak dapat terhubung ke server: $e'));
    }
  }
}
