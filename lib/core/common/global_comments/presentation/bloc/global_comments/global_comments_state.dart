part of 'global_comments_bloc.dart';

sealed class GlobalCommentsState extends Equatable {
  const GlobalCommentsState();

  @override
  List<Object> get props => [];
}

final class GlobalCommentsInitial extends GlobalCommentsState {}

final class GlobalCommentsLoading extends GlobalCommentsState {}

final class GlobalCommentsDisplaySuccess extends GlobalCommentsState {
  final List<CommentEntity> comments;

  const GlobalCommentsDisplaySuccess(this.comments);

  @override
  List<Object> get props => [comments];
}

final class GlobalCommentsLoadingCache extends GlobalCommentsState {
  final List<CommentEntity> comments;

  const GlobalCommentsLoadingCache(this.comments);

  @override
  List<Object> get props => [comments];
}

final class GlobalCommentsFailure extends GlobalCommentsState {
  final String error;

  const GlobalCommentsFailure(this.error);

  @override
  List<Object> get props => [error];
}

final class GlobalCommentsDeleteFailure extends GlobalCommentsState {
  final String error;

  const GlobalCommentsDeleteFailure({required this.error});

  @override
  List<Object> get props => [error];
}

final class GlobalCommentsDeleteSuccess extends GlobalCommentsState {}
