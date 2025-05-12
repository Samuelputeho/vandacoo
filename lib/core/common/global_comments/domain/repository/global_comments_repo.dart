import 'package:fpdart/fpdart.dart';

import '../../../../error/failure.dart';
import '../../../entities/comment_entity.dart';
import '../../../entities/post_entity.dart';

abstract interface class GlobalCommentsRepository {
  Future<Either<Failure, void>> deleteComment({
    required String commentId,
    required String userId,
  });

  Future<Either<Failure, void>> toggleBookmark(String postId);

  Future<Either<Failure, List<CommentEntity>>> getComments(String posterId);

  Future<Either<Failure, CommentEntity>> addComment(
    String posterId,
    String userId,
    String comment,
  );

  Future<Either<Failure, List<CommentEntity>>> getAllComments();

  Future<Either<Failure, List<PostEntity>>> getAllPosts(String userId);

  Future<Either<Failure, void>> updatePostCaption({
    required String postId,
    required String caption,
  });

  // Delete post
  Future<Either<Failure, void>> deletePost(String postId);

  // Report related methods
  Future<Either<Failure, void>> reportPost({
    required String postId,
    required String reporterId,
    required String reason,
    String? description,
  });

  Future<Either<Failure, bool>> hasUserReportedPost({
    required String postId,
    required String reporterId,
  });

  // Like related method
  Future<Either<Failure, void>> toggleLike({
    required String postId,
    required String userId,
  });

  Future<Either<Failure, void>> markStoryAsViewed({
    required String storyId,
    required String userId,
  });

  Future<Either<Failure, List<String>>> getViewedStories(String userId);
}
