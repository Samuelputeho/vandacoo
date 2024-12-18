part of 'like_bloc.dart';

abstract class LikeEvent {}

class ToggleLikeEvent extends LikeEvent {
  final String postId;
  final String userId;

  ToggleLikeEvent({required this.postId, required this.userId});
}

class GetLikesEvent extends LikeEvent {
  final String postId;

  GetLikesEvent(this.postId);
}