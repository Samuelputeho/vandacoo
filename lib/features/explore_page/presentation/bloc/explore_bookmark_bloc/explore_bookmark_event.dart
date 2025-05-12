abstract class ExploreBookmarkEvent {}

class ExploreToggleBookmarkEvent extends ExploreBookmarkEvent {
  final String postId;
  final String userId;

  ExploreToggleBookmarkEvent({
    required this.postId,
    required this.userId,
  });
}

class ExploreLoadBookmarkedPostsEvent extends ExploreBookmarkEvent {}
