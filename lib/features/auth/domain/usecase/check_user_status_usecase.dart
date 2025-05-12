import 'package:fpdart/fpdart.dart';
import 'package:vandacoo/core/error/failure.dart';
import 'package:vandacoo/core/usecase/usecase.dart';
import 'package:vandacoo/features/auth/domain/repository/auth_repository.dart';

class CheckUserStatus implements UseCase<bool, CheckUserStatusParams> {
  final AuthRepository authRepository;

  const CheckUserStatus(this.authRepository);

  @override
  Future<Either<Failure, bool>> call(CheckUserStatusParams params) async {
    return await authRepository.checkUserStatus(params.userId);
  }
}

class CheckUserStatusParams {
  final String userId;

  CheckUserStatusParams({required this.userId});
}
