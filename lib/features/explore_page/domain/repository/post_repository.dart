import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:vandacoo/core/common/entities/post_entity.dart';
import 'package:vandacoo/core/error/failure.dart';

import '../../../../core/common/entities/comment_entity.dart';
import '../../../../core/common/entities/message_entity.dart';
import '../../../../core/common/entities/user_entity.dart';

abstract interface class PostRepository {
  Future<Either<Failure, UserEntity>> getCurrentUserInformation(String userId);

  Future<Either<Failure, PostEntity>> uploadPost({
    required File image,
    required String userId,
    required String category,
    required String caption,
    required String region,
    required String postType,
  });

  Future<Either<Failure, List<PostEntity>>> getAllPosts(String userId);

  Future<Either<Failure, void>> markStoryAsViewed(
    String storyId,
    String viewerId,
  );

  Future<Either<Failure, List<String>>> getViewedStories(String viewerId);

  Future<Either<Failure, void>> deletePost(String postId);

  Future<Either<Failure, void>> deleteComment({
    required String commentId,
    required String userId,
  });

  //update post caption
  Future<Either<Failure, void>> updatePostCaption({
    required String postId,
    required String caption,
  });

  // Like related method
  Future<Either<Failure, void>> toggleLike({
    required String postId,
    required String userId,
  });

  //functions for the comments
  Future<Either<Failure, List<CommentEntity>>> getComments(String posterId);

  Future<Either<Failure, CommentEntity>> addComment(
    String posterId,
    String userId,
    String comment,
  );

  Future<Either<Failure, List<CommentEntity>>> getAllComments();

  Future<Either<Failure, void>> toggleBookmark({
    required String postId,
    required String userId,
  });

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

  Future<Either<Failure, MessageEntity>> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
    MessageType messageType = MessageType.text,
    File? mediaFile,
    String? mediaUrl,
  });
}
