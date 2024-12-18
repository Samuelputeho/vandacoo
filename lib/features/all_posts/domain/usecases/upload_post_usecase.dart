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
        posterId: params.posterId,
        category: params.category,
        caption: params.caption);
  }
}

class UploadPostParams {
  final String posterId;
  final String caption;
  final File image;
  final String category;
  final String region;

  UploadPostParams({
    required this.posterId,
    required this.caption,
    required this.image,
    required this.category,
    required this.region,
  });
}
