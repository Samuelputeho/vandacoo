part of 'post_bloc.dart';

@immutable
sealed class PostEvent {}

final class PostUploadEvent extends PostEvent{
final String? posterId;
  final String? caption;
  final File? image;
  final String? category;
  final String? region;
  PostUploadEvent({
    this.caption,
    this.posterId,
    this.image,
    this.category,
    this.region,
  });
}

final class GetAllPostsEvent extends PostEvent{}
