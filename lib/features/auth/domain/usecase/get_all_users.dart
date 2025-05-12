import 'package:fpdart/fpdart.dart';
import 'package:vandacoo/core/common/entities/user_entity.dart';
import 'package:vandacoo/core/error/failure.dart';
import 'package:vandacoo/core/usecase/usecase.dart';
import 'package:vandacoo/features/auth/domain/repository/auth_repository.dart';

class GetAllUsers implements UseCase<List<UserEntity>, NoParams> {
  final AuthRepository authRepository;

  const GetAllUsers(this.authRepository);
  
  @override
  Future<Either<Failure, List<UserEntity>>> call(NoParams params) async {
    return await authRepository.getAllUsers();
  }
}