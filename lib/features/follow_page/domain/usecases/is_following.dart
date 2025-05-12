import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repository/follow_page_repository.dart';

class IsFollowingUseCase implements UseCase<bool, IsFollowingParams> {
  final FollowPageRepository _followPageRepository;

  IsFollowingUseCase(this._followPageRepository);

  @override
  Future<Either<Failure, bool>> call(IsFollowingParams params) async {
    return _followPageRepository.isFollowing(
        params.followerId, params.followingId);
  }
}

class IsFollowingParams {
  final String followerId;
  final String followingId;

  IsFollowingParams({
    required this.followerId,
    required this.followingId,
  });
}
