part of 'profile_posts_bloc.dart';

sealed class ProfilePostsEvent extends Equatable {
  const ProfilePostsEvent();

  @override
  List<Object> get props => [];
}

final class GetUserPostsEvent extends ProfilePostsEvent {
  final String userId;

  const GetUserPostsEvent({required this.userId});

  @override
  List<Object> get props => [userId];
}
