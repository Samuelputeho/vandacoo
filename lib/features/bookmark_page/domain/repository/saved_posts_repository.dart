import 'package:dartz/dartz.dart';
import 'package:vandacoo/core/error/failures.dart';
import 'package:vandacoo/core/common/entities/post_entity.dart';

abstract class SavedPostsRepository {
  Future<Either<Failure, void>> toggleSavedPost(String postId);
  Future<Either<Failure, List<PostEntity>>> getSavedPosts();
}
