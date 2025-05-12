import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vandacoo/features/bookmark_page/domain/usecases/r_get_bookmarkedpost_usecase.dart';
import 'package:vandacoo/core/usecases/usecase.dart';

class BookmarkCubit extends Cubit<Map<String, bool>> {
  final SharedPreferences _prefs;
  final BookMarkPageGetBookmarkedPostsUseCase _getBookmarkedPostsUseCase;
  static const String _bookmarksKey = 'bookmarked_posts';

  BookmarkCubit({
    required SharedPreferences prefs,
    required BookMarkPageGetBookmarkedPostsUseCase getBookmarkedPostsUseCase,
  })  : _prefs = prefs,
        _getBookmarkedPostsUseCase = getBookmarkedPostsUseCase,
        super({}) {
    _loadBookmarksFromPrefs();
    _syncBookmarksWithDatabase();
  }

  void _loadBookmarksFromPrefs() {
    final bookmarks = _prefs.getStringList(_bookmarksKey) ?? [];
    final bookmarkMap = <String, bool>{};
    for (final postId in bookmarks) {
      bookmarkMap[postId] = true;
    }
    emit(bookmarkMap);
  }

  Future<void> _syncBookmarksWithDatabase() async {
    final result = await _getBookmarkedPostsUseCase(NoParams());
    result.fold(
      (failure) {
        // If database sync fails, keep using local state
      },
      (bookmarkedPostIds) {
        final bookmarkMap = <String, bool>{};
        for (final postId in bookmarkedPostIds) {
          bookmarkMap[postId] = true;
        }
        _saveBookmarksToPrefs(bookmarkMap);
        emit(bookmarkMap);
      },
    );
  }

  void _saveBookmarksToPrefs(Map<String, bool> bookmarks) {
    final bookmarkedIds = bookmarks.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
    _prefs.setStringList(_bookmarksKey, bookmarkedIds);
  }

  void setBookmarkState(String postId, bool isBookmarked) {
    final newState = Map<String, bool>.from(state);
    if (isBookmarked) {
      newState[postId] = true;
    } else {
      newState.remove(postId);
    }
    _saveBookmarksToPrefs(newState);
    emit(newState);
  }

  bool isPostBookmarked(String postId) => state[postId] ?? false;

  void refreshBookmarks() {
    _syncBookmarksWithDatabase();
  }
}
