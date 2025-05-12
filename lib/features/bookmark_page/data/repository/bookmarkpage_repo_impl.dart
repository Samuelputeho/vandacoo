import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failure.dart';
import '../../domain/repository/bookmarkpage_repository.dart';
import '../datasource/bookmarkpage_remote_datasource.dart';

class BookmarkPageRepositoryImpl implements BookmarkPageRepository {
  final BookmarkPageRemoteDataSource _remoteDataSource;

  BookmarkPageRepositoryImpl(this._remoteDataSource);

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
