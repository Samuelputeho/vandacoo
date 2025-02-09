part of 'global_comments_bloc.dart';

abstract class GlobalCommentsEvent extends Equatable {
  const GlobalCommentsEvent();

  @override
  List<Object> get props => [];
}

class GetGlobalCommentsEvent extends GlobalCommentsEvent {
  final String posterId;

  const GetGlobalCommentsEvent({required this.posterId});

  @override
  List<Object> get props => [posterId];
}

class AddGlobalCommentEvent extends GlobalCommentsEvent {
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

class GetAllGlobalCommentsEvent extends GlobalCommentsEvent {}

class DeleteGlobalCommentEvent extends GlobalCommentsEvent {
  final String commentId;
  final String userId;

  const DeleteGlobalCommentEvent({
    required this.commentId,
    required this.userId,
  });

  @override
  List<Object> get props => [commentId, userId];
}

class GetAllGlobalPostsEvent extends GlobalCommentsEvent {
  final String userId;

  const GetAllGlobalPostsEvent({required this.userId});

  @override
  List<Object> get props => [userId];
}

class UpdateGlobalPostCaptionEvent extends GlobalCommentsEvent {
  final String postId;
  final String caption;

  const UpdateGlobalPostCaptionEvent({
    required this.postId,
    required this.caption,
  });

  @override
  List<Object> get props => [postId, caption];
}

class DeleteGlobalPostEvent extends GlobalCommentsEvent {
  final String postId;

  const DeleteGlobalPostEvent({required this.postId});

  @override
  List<Object> get props => [postId];
}

class ToggleGlobalBookmarkEvent extends GlobalCommentsEvent {
  final String postId;

  const ToggleGlobalBookmarkEvent({
    required this.postId,
  });

  @override
  List<Object> get props => [postId];
}

class GlobalReportPostEvent extends GlobalCommentsEvent {
  final String postId;
  final String reporterId;
  final String reason;
  final String? description;

  const GlobalReportPostEvent({
    required this.postId,
    required this.reporterId,
    required this.reason,
    this.description,
  });

  @override
  List<Object> get props =>
      [postId, reporterId, reason, if (description != null) description!];
}

class GlobalToggleLikeEvent extends GlobalCommentsEvent {
  final String postId;
  final String userId;

  const GlobalToggleLikeEvent({
    required this.postId,
    required this.userId,
  });

  @override
  List<Object> get props => [postId, userId];
}
