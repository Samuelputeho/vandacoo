import 'package:fpdart/fpdart.dart';
import 'package:vandacoo/core/error/failure.dart';
import 'package:vandacoo/core/usecase/usecase.dart';
import 'package:vandacoo/features/auth/domain/repository/auth_repository.dart';

class ResetPasswordWithTokenUseCase
    implements UseCase<void, ResetPasswordWithTokenParams> {
  final AuthRepository authRepository;

  const ResetPasswordWithTokenUseCase(this.authRepository);

  @override
  Future<Either<Failure, void>> call(
      ResetPasswordWithTokenParams params) async {
    return await authRepository.resetPasswordWithToken(
      email: params.email,
      token: params.token,
      newPassword: params.newPassword,
    );
  }
}

class ResetPasswordWithTokenParams {
  final String email;
  final String token;
  final String newPassword;

  ResetPasswordWithTokenParams({
    required this.email,
    required this.token,
    required this.newPassword,
  });
}
