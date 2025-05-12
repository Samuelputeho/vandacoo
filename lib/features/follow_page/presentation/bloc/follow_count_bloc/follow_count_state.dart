part of 'follow_count_bloc.dart';

sealed class FollowCountState extends Equatable {
  const FollowCountState();

  @override
  List<Object> get props => [];
}

final class FollowCountInitial extends FollowCountState {}

final class FollowCountLoading extends FollowCountState {}

final class FollowCountLoadingCache extends FollowCountState {
  final FollowEntity followEntity;

  const FollowCountLoadingCache({required this.followEntity});

  @override
  List<Object> get props => [followEntity];
}

final class FollowCountError extends FollowCountState {
  final String message;

  const FollowCountError({required this.message});

  @override
  List<Object> get props => [message];
}

final class FollowCountLoaded extends FollowCountState {
  final FollowEntity followEntity;

  const FollowCountLoaded({required this.followEntity});

  @override
  List<Object> get props => [followEntity];
}
