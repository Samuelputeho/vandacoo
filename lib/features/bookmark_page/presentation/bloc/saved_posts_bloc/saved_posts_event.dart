abstract class SavedPostsEvent {}

class ToggleSavedPostEvent extends SavedPostsEvent {
  final String postId;
  final String userId;

  ToggleSavedPostEvent({
    required this.postId,
    required this.userId,
  });
}

class LoadSavedPostsEvent extends SavedPostsEvent {}
