import 'package:fpdart/fpdart.dart';
import 'package:vandacoo/core/common/entities/comment_entity.dart';
import 'package:vandacoo/core/error/failure.dart';

abstract interface class CommentRepository {
Future<Either<Failure, List<CommentEntity>>> getComments(String posterId);

  Future<Either<Failure, CommentEntity>> addComment(
    String posterId,
    String userId,
    String comment,
  );
}