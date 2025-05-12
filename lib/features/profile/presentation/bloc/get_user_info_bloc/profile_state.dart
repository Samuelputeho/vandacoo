part of 'profile_bloc.dart';

sealed class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object> get props => [];
}

final class ProfileInitial extends ProfileState {}

final class ProfileLoading extends ProfileState {}

final class ProfileLoadingCache extends ProfileState {
  final UserEntity user;

  const ProfileLoadingCache({required this.user});

  @override
  List<Object> get props => [user];
}

final class ProfileError extends ProfileState {
  final String message;

  const ProfileError({required this.message});

  @override
  List<Object> get props => [message];
}

final class ProfileUserLoaded extends ProfileState {
  final UserEntity user;

  const ProfileUserLoaded({required this.user});

  @override
  List<Object> get props => [user];
}
