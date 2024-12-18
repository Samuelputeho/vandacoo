part of 'like_bloc.dart';

abstract class LikeState {}

class LikeInitial extends LikeState {}

class LikeLoading extends LikeState {
  final String postId;
  LikeLoading(this.postId);
}

class LikeSuccess extends LikeState {
  final String postId;
  final List<String> likedByUsers;

  LikeSuccess({
    required this.postId,
    required this.likedByUsers,
  });
}

class LikeFailure extends LikeState {
  final String postId;
  final String message;

  LikeFailure({
    required this.postId,
    required this.message,
  });
}