import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SecureStorageService secureStorage;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.secureStorage,
  });

  @override
  Future<Either<Failure, User>> login(String email, String password) async {
    try {
      final response = await remoteDataSource.login(email, password);

      // Store token and user info
      await secureStorage.saveToken(response.token);
      await secureStorage.saveUserId(response.user.id);
      await secureStorage.saveUserRole(response.user.role);

      return Right(response.user);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return const Left(ServerFailure('Email atau password salah'));
      } else if (e.response?.statusCode == 400) {
        return const Left(ServerFailure('Email dan password harus diisi'));
      }
      return Left(ServerFailure(e.response?.data?['error'] ?? 'Login gagal'));
    } catch (e) {
      return Left(NetworkFailure('Tidak dapat terhubung ke server: $e'));
    }
  }

  @override
  Future<Either<Failure, User>> getProfile() async {
    try {
      final user = await remoteDataSource.getProfile();
      return Right(user);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Token might be invalid, clear it
        await secureStorage.clearAll();
        return const Left(
            ServerFailure('Sesi telah berakhir, silakan login kembali'));
      }
      return Left(ServerFailure(
          e.response?.data?['error'] ?? 'Gagal mengambil profil'));
    } catch (e) {
      return Left(NetworkFailure('Tidak dapat terhubung ke server: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await secureStorage.clearAll();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Gagal logout: $e'));
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    return await secureStorage.hasToken();
  }

  @override
  Future<String?> getUserRole() async {
    return await secureStorage.getUserRole();
  }
}
