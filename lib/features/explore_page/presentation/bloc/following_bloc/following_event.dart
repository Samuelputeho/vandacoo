part of 'following_bloc.dart';

abstract class FollowingEvent extends Equatable {
  const FollowingEvent();

  @override
  List<Object> get props => [];
}

class GetFollowingPostsEvent extends FollowingEvent {
  final String userId;

  const GetFollowingPostsEvent({required this.userId});

  @override
  List<Object> get props => [userId];
}
