part of 'comment_bloc.dart';

@immutable
sealed class CommentState {}

final class CommentInitial extends CommentState {}

final class CommentLoading extends CommentState {}

final class CommentDisplaySuccess extends CommentState {
  final List<CommentEntity> comments;

  CommentDisplaySuccess(this.comments);
}

final class CommentLoadingCache extends CommentState {
  final List<CommentEntity> comments;

  CommentLoadingCache(this.comments);
}

final class CommentFailure extends CommentState {
  final String error;

  CommentFailure(this.error);
}
