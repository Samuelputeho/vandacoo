part of 'profile_bloc.dart';

sealed class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object> get props => [];
}

final class GetUserInfoEvent extends ProfileEvent {
  final String userId;

  const GetUserInfoEvent({required this.userId});

  @override
  List<Object> get props => [userId];
}
