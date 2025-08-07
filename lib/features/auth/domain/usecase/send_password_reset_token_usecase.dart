import 'package:fpdart/fpdart.dart';
import 'package:vandacoo/core/error/failure.dart';
import 'package:vandacoo/core/usecase/usecase.dart';
import 'package:vandacoo/features/auth/domain/repository/auth_repository.dart';

class SendPasswordResetTokenUseCase
    implements UseCase<void, SendPasswordResetTokenParams> {
  final AuthRepository authRepository;

  const SendPasswordResetTokenUseCase(this.authRepository);

  @override
  Future<Either<Failure, void>> call(
      SendPasswordResetTokenParams params) async {
    return await authRepository.sendPasswordResetToken(
      email: params.email,
    );
  }
}

class SendPasswordResetTokenParams {
  final String email;

  SendPasswordResetTokenParams({
    required this.email,
  });
}
