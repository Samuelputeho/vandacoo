import 'package:fpdart/fpdart.dart';
import 'package:vandacoo/core/common/entities/post_entity.dart';

import '../../../../error/exceptions.dart';
import '../../../../error/failure.dart';
import '../../../models/comment_model.dart';
import '../../domain/repository/global_comments_repo.dart';
import '../datasource/global_comments_remote_datasource.dart';

class GlobalCommentsRepositoryImpl implements GlobalCommentsRepository {
  final GlobalCommentsRemoteDatasource remoteDatasource;

  GlobalCommentsRepositoryImpl({
    required this.remoteDatasource,
  });

  @override
  Future<Either<Failure, CommentModel>> addComment(
      String posterId, String userId, String comment) async {
    try {
      final comments =
          await remoteDatasource.addComment(posterId, userId, comment);
      return right(comments);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteComment(
      {required String commentId, required String userId}) async {
    try {
      await remoteDatasource.deleteComment(
        commentId: commentId,
        userId: userId,
      );
      return right(null);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<CommentModel>>> getAllComments() async {
    try {
      final comments = await remoteDatasource.getAllComments();
      return right(comments);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<CommentModel>>> getComments(
      String posterId) async {
    try {
      final comments = await remoteDatasource.getComments(posterId);
      return right(comments);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<PostEntity>>> getAllPosts(String userId) async {
    try {
      final posts = await remoteDatasource.getAllPosts(userId);
      return right(posts);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }
}
