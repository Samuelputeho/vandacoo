import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';
import 'package:vandacoo/core/common/entities/comment_entity.dart';
import 'package:vandacoo/core/common/entities/post_entity.dart';
import 'package:vandacoo/core/common/models/post_model.dart';
import 'package:vandacoo/core/error/exceptions.dart';
import 'package:vandacoo/core/error/failure.dart';
import 'package:vandacoo/features/explore_page/data/datasources/post_remote_data_source.dart';
import 'package:vandacoo/features/explore_page/domain/repository/post_repository.dart';

import '../../../../core/common/models/story_model.dart';

class PostRepositoryImpl implements PostRepository {
  final PostRemoteDataSource remoteDataSource;

  PostRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, PostEntity>> uploadPost({
    required File image,
    required String userId,
    required String category,
    required String caption,
    required String region,
    required String postType,
  }) async {
    try {
      PostModel postModel = PostModel(
          id: const Uuid().v1(),
          userId: userId,
          region: region,
          category: category,
          caption: caption,
          imageUrl: '',
          updatedAt: DateTime.now(),
          createdAt: DateTime.now(),
          status: 'active',
          postType: postType,
          isBookmarked: false,
          isLiked: false,
          likesCount: 0,
          isPostLikedByUser: false);

      final imageUrl =
          await remoteDataSource.uploadImage(image: image, post: postModel);

      postModel = postModel.copyWith(imageUrl: imageUrl);

      final uploadedPost = await remoteDataSource.uploadPost(postModel);
      return right(uploadedPost);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<PostEntity>>> getAllPosts(String userId) async {
    try {
      final posts = await remoteDataSource.getAllPosts(userId);
      return right(posts);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<StoryModel>>> getViewedStories(
      String userId) async {
    try {
      final viewedStories = await remoteDataSource.getViewedStories(userId);
      return right(viewedStories);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> markStoryAsViewed(
      String storyId, String viewerId) async {
    try {
      await remoteDataSource.markStoryAsViewed(storyId, viewerId);
      return right(null);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deletePost(String postId) async {
    try {
      await remoteDataSource.deletePost(postId);
      return right(null);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> updatePostCaption({
    required String postId,
    required String caption,
  }) async {
    try {
      await remoteDataSource.updatePostCaption(
        postId: postId,
        caption: caption,
      );
      return right(null);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, CommentEntity>> addComment(
      String posterId, String userId, String comment) async {
    try {
      final result =
          await remoteDataSource.addComment(posterId, userId, comment);
      return Right(result);
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
  Future<Either<Failure, void>> toggleBookmark({
    required String postId,
    required String userId,
  }) async {
    try {
      await remoteDataSource.toggleBookmark(
        postId: postId,
        userId: userId,
      );
      return right(null);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteComment({
    required String commentId,
    required String userId,
  }) async {
    try {
      await remoteDataSource.deleteComment(
        commentId: commentId,
        userId: userId,
      );
      return right(null);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> reportPost({
    required String postId,
    required String reporterId,
    required String reason,
    String? description,
  }) async {
    try {
      await remoteDataSource.reportPost(
        postId: postId,
        reporterId: reporterId,
        reason: reason,
        description: description,
      );
      return right(null);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> toggleLike({
    required String postId,
    required String userId,
  }) async {
    try {
      await remoteDataSource.toggleLike(
        postId: postId,
        userId: userId,
      );
      return right(null);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, bool>> hasUserReportedPost({
    required String postId,
    required String reporterId,
  }) async {
    try {
      final hasReported = await remoteDataSource.hasUserReportedPost(
        postId: postId,
        reporterId: reporterId,
      );
      return right(hasReported);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }
}
