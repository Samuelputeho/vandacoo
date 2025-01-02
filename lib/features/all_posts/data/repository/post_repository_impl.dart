import 'dart:io';

import 'package:fpdart/src/either.dart';
import 'package:uuid/uuid.dart';
import 'package:vandacoo/core/common/entities/post_entity.dart';
import 'package:vandacoo/core/common/models/post_model.dart';
import 'package:vandacoo/core/error/exceptions.dart';
import 'package:vandacoo/core/error/failure.dart';
import 'package:vandacoo/features/all_posts/data/datasources/post_remote_data_source.dart';
import 'package:vandacoo/features/all_posts/domain/repository/post_repository.dart';

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
          postType: postType);

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
  Future<Either<Failure, List<PostEntity>>> getAllPosts() async {
    try {
      final posts = await remoteDataSource.getAllPosts();
      return right(posts);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }
}
