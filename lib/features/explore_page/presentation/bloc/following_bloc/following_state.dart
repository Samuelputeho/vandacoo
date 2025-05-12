part of 'following_bloc.dart';

abstract class FollowingState extends Equatable {
  const FollowingState();

  @override
  List<Object> get props => [];
}

class FollowingInitial extends FollowingState {}

class FollowingLoading extends FollowingState {}

class FollowingLoadingCache extends FollowingState {
  final List<PostEntity> posts;
  final UserEntity currentUser;

  const FollowingLoadingCache({
    required this.posts,
    required this.currentUser,
  });

  @override
  List<Object> get props => [posts, currentUser];
}

class FollowingError extends FollowingState {
  final String message;

  const FollowingError({required this.message});

  @override
  List<Object> get props => [message];
}

class FollowingPostsLoaded extends FollowingState {
  final List<PostEntity> posts;
  final UserEntity currentUser;

  const FollowingPostsLoaded({
    required this.posts,
    required this.currentUser,
  });

  @override
  List<Object> get props => [posts, currentUser];
}
