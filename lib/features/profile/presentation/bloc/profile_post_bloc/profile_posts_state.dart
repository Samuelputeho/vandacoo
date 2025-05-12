part of 'profile_posts_bloc.dart';

sealed class ProfilePostsState extends Equatable {
  const ProfilePostsState();

  @override
  List<Object> get props => [];
}

final class ProfilePostsInitial extends ProfilePostsState {}

final class ProfilePostsLoading extends ProfilePostsState {}

final class ProfilePostsLoadingCache extends ProfilePostsState {
  final List<PostEntity> posts;

  const ProfilePostsLoadingCache({required this.posts});

  @override
  List<Object> get props => [posts];
}

final class ProfilePostsError extends ProfilePostsState {
  final String message;

  const ProfilePostsError({required this.message});

  @override
  List<Object> get props => [message];
}

final class ProfilePostsLoaded extends ProfilePostsState {
  final List<PostEntity> posts;

  const ProfilePostsLoaded({required this.posts});

  @override
  List<Object> get props => [posts];
}
