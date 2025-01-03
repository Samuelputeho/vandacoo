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

final class GetAllPostsEvent extends PostEvent {}
