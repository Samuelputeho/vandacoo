part of 'global_comments_bloc.dart';

abstract class GlobalCommentsState extends Equatable {
  const GlobalCommentsState();

  @override
  List<Object> get props => [];
}

class GlobalCommentsInitial extends GlobalCommentsState {}

class GlobalCommentsLoading extends GlobalCommentsState {}

class GlobalCommentsLoadingCache extends GlobalCommentsState {
  final List<CommentEntity> comments;

  const GlobalCommentsLoadingCache(this.comments);

  @override
  List<Object> get props => [comments];
}

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

class GlobalPostsLoadingCache extends GlobalCommentsState {
  final List<PostEntity> posts;

  const GlobalPostsLoadingCache(this.posts);

  @override
  List<Object> get props => [posts];
}

class GlobalPostsFailure extends GlobalCommentsState {
  final String error;

  const GlobalPostsFailure(this.error);

  @override
  List<Object> get props => [error];
}

class GlobalPostsDisplaySuccess extends GlobalCommentsState {
  final List<PostEntity> posts;

  const GlobalPostsDisplaySuccess(this.posts);

  @override
  List<Object> get props => [posts];
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

class GlobalBookmarkSuccess extends GlobalCommentsState {}

class GlobalBookmarkFailure extends GlobalCommentsState {
  final String error;

  const GlobalBookmarkFailure(this.error);

  @override
  List<Object> get props => [error];
}
