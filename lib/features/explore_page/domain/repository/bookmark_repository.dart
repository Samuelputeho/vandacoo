abstract class BookmarkRepository {
  Future<void> toggleBookmark(String postId);
  Future<List<String>> getBookmarkedPosts();
}
