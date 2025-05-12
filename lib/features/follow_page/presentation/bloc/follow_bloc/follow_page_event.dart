part of 'follow_page_bloc.dart';

abstract class FollowPageEvent extends Equatable {
  const FollowPageEvent();

  @override
  List<Object> get props => [];
}

class CheckIsFollowingEvent extends FollowPageEvent {
  final String followerId;
  final String followingId;

  const CheckIsFollowingEvent({
    required this.followerId,
    required this.followingId,
  });

  @override
  List<Object> get props => [followerId, followingId];
}

class FollowUserEvent extends FollowPageEvent {
  final String followerId;
  final String followingId;

  const FollowUserEvent({
    required this.followerId,
    required this.followingId,
  });

  @override
  List<Object> get props => [followerId, followingId];
}

class UnfollowUserEvent extends FollowPageEvent {
  final String followerId;
  final String followingId;

  const UnfollowUserEvent({
    required this.followerId,
    required this.followingId,
  });

  @override
  List<Object> get props => [followerId, followingId];
}
