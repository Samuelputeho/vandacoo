abstract class ExploreBookmarkState {}

class ExploreBookmarkInitial extends ExploreBookmarkState {}

class ExploreBookmarkLoading extends ExploreBookmarkState {}

class ExploreBookmarkSuccess extends ExploreBookmarkState {
  final bool isBookmarked;
  final List<String> bookmarkedPostIds;
  ExploreBookmarkSuccess({
    required this.isBookmarked,
    required this.bookmarkedPostIds,
  });
}

class ExploreBookmarkError extends ExploreBookmarkState {
  final String message;
  ExploreBookmarkError(this.message);
}
