import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class GetProfile implements UseCase<User, NoParams> {
  final AuthRepository repository;

  GetProfile(this.repository);

  @override
  Future<Either<Failure, User>> call(NoParams params) async {
    return await repository.getProfile();
  }
}
