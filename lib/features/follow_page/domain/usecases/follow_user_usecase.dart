import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../repository/follow_page_repository.dart';

class FollowUserUsecase implements UseCase<void, FollowUserParams> {
  final FollowPageRepository followPageRepository;

  FollowUserUsecase(this.followPageRepository);

  @override
  Future<Either<Failure, void>> call(FollowUserParams params) async {
    return followPageRepository.followUser(
      params.followerId,
      params.followingId,
    );
  }
}

class FollowUserParams {
  final String followerId;
  final String followingId;

  FollowUserParams({
    required this.followerId,
    required this.followingId,
  });
}
