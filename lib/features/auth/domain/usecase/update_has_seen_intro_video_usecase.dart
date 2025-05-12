import 'package:fpdart/fpdart.dart';
import 'package:vandacoo/core/error/failure.dart';
import 'package:vandacoo/core/usecase/usecase.dart';
import 'package:vandacoo/features/auth/domain/repository/auth_repository.dart';

class UpdateHasSeenIntroVideo implements UseCase<void, String> {
  final AuthRepository authRepository;
  const UpdateHasSeenIntroVideo(this.authRepository);

  @override
  Future<Either<Failure, void>> call(String userId) async {
    return await authRepository.updateHasSeenIntroVideo(userId);
  }
}
