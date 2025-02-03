import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:vandacoo/core/common/entities/post_entity.dart';
import 'package:vandacoo/core/common/entities/story_entitiy.dart';
import 'package:vandacoo/core/error/failure.dart';

abstract interface class PostRepository {
  Future<Either<Failure, PostEntity>> uploadPost({
    required File image,
    required String userId,
    required String category,
    required String caption,
    required String region,
    required String postType,
  });

  Future<Either<Failure, List<PostEntity>>> getAllPosts();

  Future<Either<Failure, void>> markStoryAsViewed(
    String storyId,
    String viewerId,
  );

  Future<Either<Failure, List<StoryEntity>>> getViewedStories(String viewerId);

  Future<Either<Failure, void>> deletePost(String postId);

  //update post caption
  Future<Either<Failure, void>> updatePostCaption({
    required String postId,
    required String caption,
  });
}
