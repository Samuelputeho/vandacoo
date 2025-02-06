import 'package:dartz/dartz.dart';
import 'package:vandacoo/core/error/failures.dart';
import 'package:vandacoo/core/common/entities/post_entity.dart';
import 'package:vandacoo/features/bookmark_page/data/datasources/saved_posts_remote_data_source.dart';
import 'package:vandacoo/features/bookmark_page/domain/repository/saved_posts_repository.dart';

class SavedPostsRepositoryImpl implements SavedPostsRepository {
  final SavedPostsRemoteDataSource remoteDataSource;

  SavedPostsRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, void>> toggleSavedPost(String postId) async {
    try {
      await remoteDataSource.toggleSavedPost(postId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PostEntity>>> getSavedPosts() async {
    try {
      final posts = await remoteDataSource.getSavedPosts();
      return Right(posts);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
