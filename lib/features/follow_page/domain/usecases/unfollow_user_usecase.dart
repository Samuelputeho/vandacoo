import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repository/follow_page_repository.dart';

class UnfollowUserUsecase implements UseCase<void, UnfollowUserParams> {
  final FollowPageRepository followPageRepository;

  UnfollowUserUsecase(this.followPageRepository);

  @override
  Future<Either<Failure, void>> call(UnfollowUserParams params) async {
    return followPageRepository.unfollowUser(
      params.followerId,
      params.followingId,
    );
  }
}

class UnfollowUserParams {
  final String followerId;
  final String followingId;

  UnfollowUserParams({
    required this.followerId,
    required this.followingId,
  });
}
