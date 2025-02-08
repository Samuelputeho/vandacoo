import 'package:fpdart/fpdart.dart';

import '../../../../error/failure.dart';
import '../../../entities/comment_entity.dart';
import '../../../entities/post_entity.dart';

abstract interface class GlobalCommentsRepository {
  Future<Either<Failure, void>> deleteComment({
    required String commentId,
    required String userId,
  });

  Future<Either<Failure, List<CommentEntity>>> getComments(String posterId);

  Future<Either<Failure, CommentEntity>> addComment(
    String posterId,
    String userId,
    String comment,
  );

  Future<Either<Failure, List<CommentEntity>>> getAllComments();

  Future<Either<Failure, List<PostEntity>>> getAllPosts(String userId);
}
