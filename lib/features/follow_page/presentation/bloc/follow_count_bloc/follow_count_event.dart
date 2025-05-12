part of 'follow_count_bloc.dart';

sealed class FollowCountEvent extends Equatable {
  const FollowCountEvent();

  @override
  List<Object> get props => [];
}

final class GetUserCountsEvent extends FollowCountEvent {
  final String userId;

  const GetUserCountsEvent({required this.userId});

  @override
  List<Object> get props => [userId];
}
