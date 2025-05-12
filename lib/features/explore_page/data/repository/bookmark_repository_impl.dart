import 'package:fpdart/src/either.dart';
import 'package:vandacoo/core/error/failure.dart';
import 'package:vandacoo/features/explore_page/data/datasources/bookmark_remote_data_source.dart';
import 'package:vandacoo/features/explore_page/domain/repository/bookmark_repository.dart';

import '../../../../core/error/exceptions.dart';

class BookmarkRepositoryImpl implements BookmarkRepository {
  final BookmarkRemoteDataSource _remoteDataSource;

  BookmarkRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<String>>> getBookmarkedPosts() async {
    try {
      final posts = await _remoteDataSource.getBookmarkedPosts();
      return right(posts);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> toggleBookmark(String postId) async {
    try {
      await _remoteDataSource.toggleBookmark(postId);
      return right(null);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }
}
