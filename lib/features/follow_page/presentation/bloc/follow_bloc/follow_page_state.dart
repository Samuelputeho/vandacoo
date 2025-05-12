part of 'follow_page_bloc.dart';

sealed class FollowPageState extends Equatable {
  const FollowPageState();

  @override
  List<Object> get props => [];
}

final class FollowPageInitial extends FollowPageState {}

final class FollowPageLoading extends FollowPageState {}

final class FollowPageLoadingCache extends FollowPageState {
  final bool isFollowing;

  const FollowPageLoadingCache({required this.isFollowing});

  @override
  List<Object> get props => [isFollowing];
}

final class FollowPageError extends FollowPageState {
  final String message;

  const FollowPageError(this.message);

  @override
  List<Object> get props => [message];
}

final class FollowPageSuccess extends FollowPageState {}

final class IsFollowingState extends FollowPageState {
  final bool isFollowing;

  const IsFollowingState(this.isFollowing);

  @override
  List<Object> get props => [isFollowing];
}
