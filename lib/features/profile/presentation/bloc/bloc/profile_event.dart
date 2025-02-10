part of 'profile_bloc.dart';

sealed class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object> get props => [];
}

class GetUserPostsEvent extends ProfileEvent {
  final String userId;

  const GetUserPostsEvent({required this.userId});

  @override
  List<Object> get props => [userId];
}
