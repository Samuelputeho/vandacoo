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
