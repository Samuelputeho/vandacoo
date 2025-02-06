import 'package:vandacoo/features/explore_page/data/datasources/bookmark_remote_data_source.dart';
import 'package:vandacoo/features/explore_page/domain/repository/bookmark_repository.dart';

class BookmarkRepositoryImpl implements BookmarkRepository {
  final BookmarkRemoteDataSource _remoteDataSource;

  BookmarkRepositoryImpl(this._remoteDataSource);

  @override
  Future<void> toggleBookmark(String postId) {
    return _remoteDataSource.toggleBookmark(postId);
  }

  @override
  Future<List<String>> getBookmarkedPosts() {
    return _remoteDataSource.getBookmarkedPosts();
  }
}
