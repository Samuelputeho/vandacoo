import 'package:fpdart/fpdart.dart';
import 'package:vandacoo/core/error/exceptions.dart';
import 'package:vandacoo/core/error/failure.dart';
import 'package:vandacoo/features/likes/data/datasources/like_remote_data_source.dart';
import 'package:vandacoo/features/likes/domain/repository/like_repository.dart';

class LikeRepositoryImpl implements LikeRepository {
  final LikeRemoteDataSource remoteDataSource;

  LikeRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, void>> toggleLike(String postId, String userId) async {
    try {
      await remoteDataSource.toggleLike(postId, userId);
      return right(null);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getLikes(String postId) async {
    try {
      final likes = await remoteDataSource.getLikes(postId);
      return right(likes);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }
}