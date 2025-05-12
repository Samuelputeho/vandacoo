part of 'post_bloc.dart';

@immutable
sealed class PostState {}

final class PostInitial extends PostState {}

final class PostLoading extends PostState {}

final class PostFailure extends PostState {
  final String error;

  PostFailure(this.error);
}

final class PostSuccess extends PostState {}

final class PostDisplaySuccess extends PostState {
  final List<PostEntity> posts;
  final List<PostEntity> stories;

  PostDisplaySuccess({
    required this.posts,
    required this.stories,
  });
}

final class PostLoadingCache extends PostState {
  final List<PostEntity> posts;
  final List<PostEntity> stories;

  PostLoadingCache({
    required this.posts,
    required this.stories,
  });
}

final class PostDeleteSuccess extends PostState {}

final class PostDeleteFailure extends PostState {
  final String error;

  PostDeleteFailure(this.error);
}

final class PostUpdateCaptionSuccess extends PostState {}

final class PostUpdateCaptionFailure extends PostState {
  final String error;

  PostUpdateCaptionFailure(this.error);
}

class PostBookmarkSuccess extends PostState {
  final bool isBookmarked;
  PostBookmarkSuccess(this.isBookmarked);
}

class PostBookmarkError extends PostState {
  final String error;
  PostBookmarkError(this.error);
}

// Report states
class PostReportSuccess extends PostState {}

class PostReportFailure extends PostState {
  final String error;
  PostReportFailure(this.error);
}

class PostAlreadyReportedState extends PostState {}

// Like states
class PostLikeSuccess extends PostState {
  final bool isLiked;
  PostLikeSuccess(this.isLiked);
}

class PostLikeError extends PostState {
  final String error;
  PostLikeError(this.error);
}

class GetCurrentUserInformationSuccess extends PostState {
  final UserEntity user;
  GetCurrentUserInformationSuccess(this.user);
}

class GetCurrentUserInformationFailure extends PostState {
  final String error;
  GetCurrentUserInformationFailure(this.error);
}

class PostStoryViewSuccess extends PostState {
  final String viewedStoryId;
  final List<PostEntity> posts;
  final List<PostEntity> stories;
  final Set<String> viewedStories;

  PostStoryViewSuccess({
    required this.viewedStoryId,
    required this.posts,
    required this.stories,
    required this.viewedStories,
  });
}

class PostStoryViewFailure extends PostState {
  final String error;
  PostStoryViewFailure(this.error);
}
