part of 'users_bloc.dart';

@immutable
abstract class UsersState {}

class UsersInitial extends UsersState {}

class UsersLoading extends UsersState {}

class UsersLoaded extends UsersState {
  final List<UserEntity> users;

  UsersLoaded(this.users);
}

class UsersFailure extends UsersState {
  final String message;

  UsersFailure(this.message);
}
