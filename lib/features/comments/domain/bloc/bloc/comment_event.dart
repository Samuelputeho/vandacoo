part of 'comment_bloc.dart';

@immutable
sealed class CommentEvent {}

final class GetCommentsEvent extends CommentEvent {
  final String posterId;

  GetCommentsEvent(this.posterId);
}

final class AddCommentEvent extends CommentEvent {
  final String posterId;
  final String userId;
  final String comment;

  AddCommentEvent({
    required this.posterId,
    required this.userId,
    required this.comment,
  });
}
