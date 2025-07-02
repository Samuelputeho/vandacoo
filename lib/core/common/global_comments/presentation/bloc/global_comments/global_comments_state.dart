part of 'global_comments_bloc.dart';

abstract class GlobalCommentsState extends Equatable {
  const GlobalCommentsState();

  @override
  List<Object> get props => [];
}

class GlobalCommentsInitial extends GlobalCommentsState {}

class GlobalCommentsLoading extends GlobalCommentsState {}

class GlobalCommentsFailure extends GlobalCommentsState {
  final String error;

  const GlobalCommentsFailure(this.error);

  @override
  List<Object> get props => [error];
}

class GlobalCommentsDisplaySuccess extends GlobalCommentsState {
  final List<CommentEntity> comments;

  const GlobalCommentsDisplaySuccess(this.comments);

  @override
  List<Object> get props => [comments];
}

class GlobalCommentsDeleteSuccess extends GlobalCommentsState {}

class GlobalCommentsDeleteFailure extends GlobalCommentsState {
  final String error;

  const GlobalCommentsDeleteFailure({required this.error});

  @override
  List<Object> get props => [error];
}

// Post-related states
class GlobalPostsLoading extends GlobalCommentsState {}

class GlobalPostsFailure extends GlobalCommentsState {
  final String message;

  const GlobalPostsFailure(this.message);

  @override
  List<Object> get props => [message];
}

class GlobalPostsDisplaySuccess extends GlobalCommentsState {
  final List<PostEntity> posts;
  final List<PostEntity> stories;

  const GlobalPostsDisplaySuccess(this.posts, {required this.stories});

  @override
  List<Object> get props => [posts, stories];
}

// Combined state that holds both posts and comments
class GlobalPostsAndCommentsSuccess extends GlobalCommentsState {
  final List<PostEntity> posts;
  final List<PostEntity> stories;
  final List<CommentEntity> comments;

  const GlobalPostsAndCommentsSuccess({
    required this.posts,
    required this.stories,
    required this.comments,
  });

  @override
  List<Object> get props => [posts, stories, comments];
}

class GlobalPostUpdateSuccess extends GlobalCommentsState {}

class GlobalPostUpdateFailure extends GlobalCommentsState {
  final String error;

  const GlobalPostUpdateFailure(this.error);

  @override
  List<Object> get props => [error];
}

class GlobalPostDeleteSuccess extends GlobalCommentsState {}

class GlobalPostDeleteFailure extends GlobalCommentsState {
  final String error;

  const GlobalPostDeleteFailure(this.error);

  @override
  List<Object> get props => [error];
}

// Bookmark states
class GlobalBookmarkLoading extends GlobalCommentsState {}

class GlobalBookmarkSuccess extends GlobalCommentsState {}

class GlobalBookmarkFailure extends GlobalCommentsState {
  final String error;

  const GlobalBookmarkFailure(this.error);

  @override
  List<Object> get props => [error];
}

// Report states
class GlobalPostReportSuccess extends GlobalCommentsState {}

class GlobalPostReportFailure extends GlobalCommentsState {
  final String error;

  const GlobalPostReportFailure(this.error);

  @override
  List<Object> get props => [error];
}

class GlobalPostAlreadyReportedState extends GlobalCommentsState {}

// Like states
class GlobalLikeSuccess extends GlobalCommentsState {
  const GlobalLikeSuccess();
}

class GlobalLikeError extends GlobalCommentsState {
  final String error;

  const GlobalLikeError(this.error);

  @override
  List<Object> get props => [error];
}
