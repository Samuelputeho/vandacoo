import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/follow_entity.dart';

abstract interface class FollowPageRepository {
  /// Follow a user
  Future<Either<Failure, void>> followUser(
    String followerId,
    String followingId,
  );

  /// Unfollow a user
  Future<Either<Failure, void>> unfollowUser(
    String followerId,
    String followingId,
  );

  //is following
  Future<Either<Failure, bool>> isFollowing(
    String followerId,
    String followingId,
  );

  //get user counts
  Future<Either<Failure, FollowEntity>> getUserCounts(String userId);
}
