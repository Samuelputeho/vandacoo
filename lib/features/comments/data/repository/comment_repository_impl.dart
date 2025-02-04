import 'package:fpdart/fpdart.dart';
import 'package:vandacoo/core/common/entities/comment_entity.dart';
import 'package:vandacoo/core/error/exceptions.dart';
import 'package:vandacoo/core/error/failure.dart';
import 'package:vandacoo/features/comments/data/datasources/comment_remote_data_source.dart';
import 'package:vandacoo/features/comments/domain/repository/comment_reposirory.dart';

class CommentRepositoryImpl implements CommentRepository {
  final CommentRemoteDataSource remoteDataSource;

  CommentRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<CommentEntity>>> getComments(
      String posterId) async {
    try {
      final comments = await remoteDataSource.getComments(posterId);
      return Right(comments);
    } on ServerException catch (e) {
      return Left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<CommentEntity>>> getAllComments() async {
    try {
      final comments = await remoteDataSource.getAllComments();
      return Right(comments);
    } on ServerException catch (e) {
      return Left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, CommentEntity>> addComment(
    String posterId,
    String userId,
    String comment,
  ) async {
    try {
      final result =
          await remoteDataSource.addComment(posterId, userId, comment);
      return Right(result);
    } on ServerException catch (e) {
      return Left(Failure(e.message));
    }
  }
}
