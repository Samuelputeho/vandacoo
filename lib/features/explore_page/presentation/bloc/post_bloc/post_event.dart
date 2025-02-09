part of 'post_bloc.dart';

@immutable
sealed class PostEvent {}

final class PostUploadEvent extends PostEvent {
  final String? userId;
  final String? caption;
  final File? image;
  final String? category;
  final String? region;
  final String? postType;
  PostUploadEvent({
    this.caption,
    this.userId,
    this.image,
    this.category,
    this.region,
    this.postType,
  });
}

final class GetAllPostsEvent extends PostEvent {
  final String userId;
  GetAllPostsEvent({required this.userId});
}

class MarkStoryViewedEvent extends PostEvent {
  final String storyId;
  final String viewerId;

  MarkStoryViewedEvent({
    required this.storyId,
    required this.viewerId,
  });
}

class DeletePostEvent extends PostEvent {
  final String postId;
  DeletePostEvent({required this.postId});
}

class UpdatePostCaptionEvent extends PostEvent {
  final String postId;
  final String caption;
  UpdatePostCaptionEvent({
    required this.postId,
    required this.caption,
  });
}

class LoadBookmarkedPostsEvent extends PostEvent {}

class ToggleBookmarkEvent extends PostEvent {
  final String postId;
  final String userId;

  ToggleBookmarkEvent({
    required this.postId,
    required this.userId,
  });
}

class ReportPostEvent extends PostEvent {
  final String postId;
  final String reporterId;
  final String reason;
  final String? description;

  ReportPostEvent({
    required this.postId,
    required this.reporterId,
    required this.reason,
    this.description,
  });
}

class ToggleLikeEvent extends PostEvent {
  final String postId;
  final String userId;

  ToggleLikeEvent({
    required this.postId,
    required this.userId,
  });
}
