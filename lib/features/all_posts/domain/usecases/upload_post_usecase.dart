import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:vandacoo/core/common/entities/post_entity.dart';
import 'package:vandacoo/core/error/failure.dart';
import 'package:vandacoo/core/usecase/usecase.dart';
import 'package:vandacoo/features/all_posts/domain/repository/post_repository.dart';

class UploadPost implements UseCase<PostEntity, UploadPostParams> {
  final PostRepository postRepository;

  UploadPost({required this.postRepository});
  @override
  Future<Either<Failure, PostEntity>> call(UploadPostParams params) async {
    return await postRepository.uploadPost(
        image: params.image,
        region: params.region,
        userId: params.userId,
        category: params.category,
        caption: params.caption,
        postType: params.postType);
  }
}

class UploadPostParams {
  final String userId;
  final String caption;
  final File image;
  final String category;
  final String region;
  final String postType;

  UploadPostParams({
    required this.userId,
    required this.caption,
    required this.image,
    required this.category,
    required this.region,
    required this.postType,
  });
}
