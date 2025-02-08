part of 'global_comments_bloc.dart';

sealed class GlobalCommentsEvent extends Equatable {
  const GlobalCommentsEvent();

  @override
  List<Object> get props => [];
}

final class GetGlobalCommentsEvent extends GlobalCommentsEvent {
  final String posterId;

  const GetGlobalCommentsEvent(this.posterId);

  @override
  List<Object> get props => [posterId];
}

final class AddGlobalCommentEvent extends GlobalCommentsEvent {
  final String posterId;
  final String userId;
  final String comment;

  const AddGlobalCommentEvent({
    required this.posterId,
    required this.userId,
    required this.comment,
  });

  @override
  List<Object> get props => [posterId, userId, comment];
}

final class GetAllGlobalCommentsEvent extends GlobalCommentsEvent {}

final class DeleteGlobalCommentEvent extends GlobalCommentsEvent {
  final String commentId;
  final String userId;

  const DeleteGlobalCommentEvent({
    required this.commentId,
    required this.userId,
  });

  @override
  List<Object> get props => [commentId, userId];
}
